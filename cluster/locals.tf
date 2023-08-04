locals {
  # General
  region          = "eu-west-1" # zurich has not yet all available instance types + a lab should be as cheap as possible
  cluster_name    = "banana-bread"
  cluster_version = "1.27"
  account_id      = "296119450228"

  # Compute
  min_node_size        = 0
  max_node_size        = 5
  instance_types_amd64 = ["t3a.medium", "t3.medium", "t2.medium"]
  instance_types_arm64 = ["t4g.medium", "c6g.large", "c6gd.large", "c6gn.large"]
  volume_type          = "gp3"
  volume_size          = 20

  # Networking
  vpc_name             = "banana-bread"
  vpc_cidr             = "10.123.0.0/16"
  cluster_service_cidr = "172.20.0.0/16" # change to 10.127.0.0/16 next time 
  dns_zone             = "aws.alleaffengaffen.ch"
  create_dns_zone      = true # NS records still have to be added manually
  ingress_class        = "nginx"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)

  # GitOps
  sync_options = ["ServerSideApply=true", "PruneLast=true", "ApplyOutOfSyncOnly=true", "PrunePropagationPolicy=foreground", "CreateNamespace=false"]


  # IAM
  acme_mail = "banane@alleaffengaffen.ch"
  cluster_admins = [
    {
      userarn  = "arn:aws:iam::${local.account_id}:user/axiom"
      username = "axiom"
      groups   = ["system:masters"]
    },

  ]
  cluster_admin_arns = formatlist("%s", local.cluster_admins[*].userarn)

  # Mish
  nodegroup_hash = "foo"

  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
