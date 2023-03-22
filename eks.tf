module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.9"

  cluster_name    = local.name
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
  aws_auth_users            = local.aws_auth_users

  # Data-plane
  eks_managed_node_groups = {
    minions = {
      name            = "minions"
      use_name_prefix = true

      capacity_type  = "SPOT"
      instance_types = local.instance_types

      update_config = {
        max_unavailable_percentage = 33
      }

      ami_type = local.ami_type

      min_size     = local.min_size
      max_size     = local.max_size
      desired_size = local.desired_size

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      taints = [
        # will be removed by cilium once initialized
        {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      ]
    }
  }

  tags = local.tags
}
