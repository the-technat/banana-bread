module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.9"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  # IPV6
  cluster_ip_family = "ipv6"

  # We are using the IRSA created below for permissions
  # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
  # and then turn this off after the cluster/node group is created. Without this initial policy,
  # the VPC CNI fails to assign IPs and nodes cannot join the cluster
  # See https://github.com/aws/containers-roadmap/issues/1666 for more context
  create_cni_ipv6_iam_policy = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::298410952490:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
  ]

  eks_managed_node_groups = {
    minions = {
      name            = "minions"
      use_name_prefix = true
      capacity_type   = "SPOT"
      instance_types  = local.instance_types

      update_config = {
        max_unavailable_percentage = 33
      }

      ami_type = local.ami_type
      platform = local.platform

      min_size     = local.min_size
      max_size     = local.max_size
      desired_size = local.desired_size

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  tags = local.tags
}
