locals {
  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
  region          = "eu-central-1"
  cluster_version = "1.24"
  cluster_name    = "banana-bread"
  account_id      = "298410952490"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_addons = {
    coredns = {
      addon_version     = "v1.9.3-eksbuild.2"
      resolve_conflicts = "OVERWRITE"

    }
    kube-proxy = {
      addon_version     = "v1.24.9-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.12.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Loggging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Networking
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_security_group_id      = aws_security_group.eks_cluster.id
  create_cluster_security_group  = false # don't create an extra SG for the cluster
  create_node_security_group     = false # don't create an extra SG for the nodes
  cluster_endpoint_public_access = true

  # IAM
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::298410952490:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::298410952490:user/codespace"
      username = "codespace"
      groups   = ["system:masters"]
    },
  ]

  # Data-plane
  eks_managed_node_group_defaults = {
    # general
    use_name_prefix = true
    ami_id          = "ami-029bc1687a2afeb19"
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }

    # IAM
    iam_role_attach_cni_policy = true


    # Compute
    ami_type       = "AL2_x86_64"
    instance_types = ["t3a.xlarge", "t3.xlarge", "t2.xlarge"]
    capacity_type  = "SPOT"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 20
          volume_type           = "gp3"
          delete_on_termination = true
        }
      }
    }
    ebs_optimized     = true
    enable_monitoring = true


    # networking
    network_interfaces = [
      {
        associate_public_ip_address = false
        delete_on_termination       = true
        security_groups             = [module.eks.cluster_primary_security_group_id, aws_security_group.eks_cluster.id]
      }
    ]

    # scaling
    min_size     = 0
    max_size     = 3
    desired_size = 1

    # IAM
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]

    # K8s
    enable_bootstrap_user_data = true
    bootstrap_extra_args       = "--kubelet-extra-args '--node-labels=cluster=${local.cluster_name}' --container-runtime containerd"
    taints = [
      # will be removed by cilium once initialized
      {
        key    = "node.cilium.io/agent-not-ready"
        value  = "true"
        effect = "NO_EXECUTE"
      }
    ]
    update_config = {
      max_unavailable_percentage = 33
    }
    force_update_version = true

  }
  eks_managed_node_groups = {
    minions = {
      name       = "minions"
      subnet_ids = [module.vpc.private_subnets[0]]
    }
    donkeys = {
      name       = "donkeys"
      subnet_ids = [module.vpc.private_subnets[1]]
    }
    cows = {
      name       = "cows"
      subnet_ids = [module.vpc.private_subnets[2]]
    }
    # parrots = {
    #   name       = "parrots"
    #   subnet_ids = module.vpc.private_subnets
    #   ami_type   = "AL2_ARM_64"
    #   ami_id     =  data.aws_ami.eks_default_arm.image_id
    # }
    # rockets = {
    #   name = "rockets"
    #   ami_type = "BOTTLEROCKET_x86_64"
    #   platform = "bottlerocket"
    # }
  }

  tags = local.tags
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}

data "aws_ami" "eks_default_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-arm64-node-${local.cluster_version}-v*"]
  }
}

###############
# Cilium
##############
# We use cilium in cni-chaining mode with aws-vpc-cni
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.12.5"
  namespace  = "kube-system"
  wait       = true

  values = [
    templatefile("${path.module}/helm_values/cilium_values.yaml", {
    })
  ]

  depends_on = [
    module.eks.aws_eks_cluster
  ]
}
