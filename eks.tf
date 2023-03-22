locals {
  tags = {
    Cluster    = "banana_bread"
    GithubRepo = "github.com/alleaffengaffen/banana_bread"
  }
  region = "eu-central-2"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.9"

  cluster_name    = "banana_bread"
  cluster_version = "1.24"

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
  eks_managed_node_groups = {
    minions = {
      name            = "minions"
      use_name_prefix = true

      capacity_type  = "SPOT"
      instance_types = ["t3a.medium", "t3.medium"]

      update_config = {
        max_unavailable_percentage = 33
      }

      ami_type = "AL2_x86_64"

      min_size     = 0
      max_size     = 3
      desired_size = 1

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
