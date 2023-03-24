locals {
  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
  region          = "eu-central-1"
  cluster_version = "1.25"
  cluster_name    = "banana-bread"
  account_id      = "298410952490"

  vpc_cidr = "10.123.0.0/16"
  vpc_name = "banana-bread"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {}
