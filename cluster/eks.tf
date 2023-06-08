module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      # if cilium is set, kube-proxy will be purged
      most_recent = true
    }
    vpc-cni = {
      # if cilium is set, vpc-cni will be purged
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Networking
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  create_cluster_security_group  = false # we just use the eks-managed SG
  create_node_security_group     = false # we just use the eks-managed SG

  # IAM
  manage_aws_auth_configmap = true
  aws_auth_users            = local.cluster_admins

  // settings in this block apply to all nodes groups
  eks_managed_node_group_defaults = {
    # General
    use_name_prefix = true
    taints = [
      {
        key    = "node.cilium.io/agent-not-ready"
        value  = "true"
        effect = "NO_EXECUTE"
      }
    ] 
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled" # only non-default setting
    }
    update_config = {
      max_unavailable_percentage = 33 # module's default, stable but still fast
    }
    force_update_version = true # after 15min of unsuccessful draining, pods are force-killed


    # Compute
    capacity_type = "SPOT" # is it a lab or not?
    min_size      = 0
    max_size      = 5
    desired_size  = 2

    # Networking
    network_interfaces = [
      {
        delete_on_termination = true
        security_groups       = [module.eks.cluster_primary_security_group_id] # use eks-managed SG for everything
      }
    ]

    # Storage
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 20
          volume_type           = "gp3"
          iops                  = 3000 # default for gp3
          throughput            = 150  # default for gp3
          encrypted             = true
          kms_key_id            = module.ebs_kms_key.key_arn
          delete_on_termination = true
        }
      }
    }

    # IAM
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    }
    iam_role_attach_cni_policy = true

    // required since we specify the AMI to use
    // otherwise the nodes don't join
    // setting also assume the default eks image is used
    enable_bootstrap_user_data = true

  }

  eks_managed_node_groups = {
    # minions = {
    #   name           = "minions"
    #   ami_type       = "AL2_ARM_64"
    #   instance_types = ["t4g.medium", "c6g.large", "c6gd.large", "c6gn.large"]
    #   subnet_ids     = module.vpc.private_subnets
    #   ami_id         = data.aws_ami.eks_default_arm.image_id
    #   desired_size   = 0 # by default we don't need arm64 nodes
    #   taints = [
    #     {
    #       key    = "node.cilium.io/agent-not-ready"
    #       value  = "true"
    #       effect = "NO_EXECUTE"
    #     },
    #     {
    #       key    = "beta.kubernetes.io/arch"
    #       value  = "arm64"
    #       effect = "NO_EXECUTE"
    #     }
    #   ]
    # }
    lions = {
      name           = "lions"
      ami_type       = "AL2_x86_64"
      instance_types = ["t3a.medium", "t3.medium", "t2.medium"]
      subnet_ids     = module.vpc.private_subnets
      # ami_id         = data.aws_ami.eks_default.image_id
      ami_id ="ami-0523dba30d36cfe4b"

    }
  }

  tags = local.tags
}


# use pre-build images by AWS
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

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = concat([data.aws_caller_identity.current.arn], local.cluster_admin_arns)
  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${local.cluster_name}/ebs"]

  tags = local.tags
}