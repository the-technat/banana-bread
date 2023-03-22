locals {
  tags = {
    Cluster    = "banana_bread"
    GithubRepo = "github.com/alleaffengaffen/banana_bread"
  }
  region = "eu-central-2"
  cluster_version = "1.24"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.9"

  cluster_name    = "banana_bread"
  cluster_version = local.cluster_version

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  # Networking
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # IAM
  manage_aws_auth_configmap = true
  aws_auth_users            = [
    {
      userarn  = "arn:aws:iam::298410952490:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
  ]

  # Data-plane
  eks_managed_node_group_defaults = {
    # general
    use_name_prefix = true

    # compute
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
    ami_id         = data.aws_ami.eks_default.image_id
    capacity_type  = "SPOT"

    # scaling
    min_size = 0
    max_size = 3
    desired_size = 1

    # IAM
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # K8s
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
    #   ami_id     = data.aws_ami.eks_default_arm.image_id
    # }
  }

  tags = local.tags
}

###############
# AMIs
###############
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

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${local.cluster_version}-x86_64-*"]
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
  version    = "1.11.4"
  namespace  = "kube-system"
  wait = true

  values = [ 
    templatefile("${path.module}/helm_values/cilium_values.yaml", {
    })
  ]

  depends_on = [
    module.eks.aws_eks_cluster
  ]
}