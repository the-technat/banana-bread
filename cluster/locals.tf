locals {
  # General
  region          = "sa-east-1" # zurich has not yet all available instance types + a lab should be as cheap as possible
  cluster_name    = "banana-bread"
  cluster_version = "1.27"
  account_id      = "298410952490"

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
      userarn  = "arn:aws:iam::${local.account_id}:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${local.account_id}:user/nuker"
      username = "nuker"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::732912165649:user/m2banana"
      username = "m2banana"
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
