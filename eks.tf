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
  ]

  eks_managed_node_group_defaults = {
    use_name_prefix = true

    capacity_type  = "SPOT"
    ami_type       = "AL2_x86_64"
    ami_id         = "ami-029bc1687a2afeb19" # amazon-aws-eks-node-1.24-v*
    instance_types = ["t3a.xlarge", "t3.xlarge", "t2.xlarge"]

    min_size     = 0
    max_size     = 10
    desired_size = 3

    network_interfaces = [
      {
        associate_public_ip_address = false
        delete_on_termination       = true
        security_groups             = [module.eks.cluster_primary_security_group_id, aws_security_group.eks_cluster.id]
      }
    ]

    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ]

    enable_bootstrap_user_data = true
    taints = [
      # will be removed by cilium once initialized
      {
        key    = "node.cilium.io/agent-not-ready"
        value  = "true"
        effect = "NO_EXECUTE"
      }
    ]
  }
  eks_managed_node_groups = {
    minions1 = {
      name       = "minions1"
      subnet_ids = [module.vpc.private_subnets[0]]
    }
    minions2 = {
      name       = "minions2"
      subnet_ids = [module.vpc.private_subnets[1]]
    }
    minions3 = {
      name       = "minions3"
      subnet_ids = [module.vpc.private_subnets[2]]
    }
  }

  tags = local.tags
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-custom"
  description = "Custom Cluster Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
  }
}
