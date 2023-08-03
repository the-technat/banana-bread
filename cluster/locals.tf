locals {
  # General
  region          = "sa-east-1" # zurich has not yet all available instance types + a lab should be as cheap as possible
  cluster_name    = "banana-bread"
  cluster_version = "1.27"
  account_id      = "296119450228"

  # Networking
  vpc_name      = "banana-bread"
  vpc_cidr      = "10.123.0.0/16"
  dns_zone      = "aws.alleaffengaffen.ch"
  ingress_class = "nginx"
  azs           = slice(data.aws_availability_zones.available.names, 0, 3)

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

  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
