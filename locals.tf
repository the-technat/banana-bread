locals {
  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
  region          = "sa-east-1" # zurich has not yet all available instance types + a lab should be as cheap as possible
  cluster_name    = "banana-bread"
  cluster_version = "1.25"
  account_id      = "298410952490"

  vpc_name = "banana-bread"
  vpc_cidr = "10.123.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  cluster_admins = [
    {
      userarn  = "arn:aws:iam::${local.account_id}:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
  ]
  cluster_admin_arns = formatlist("%s", local.cluster_admins[*].userarn)
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
