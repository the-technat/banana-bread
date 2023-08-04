locals {
  # General
  region          = "eu-west-1" # zurich has not yet all available instance types + a lab should be as cheap as possible
  cluster_name    = "banana-bread"
  cluster_version = "1.27"
  account_id      = "296119450228"

  # Networking
  vpc_name        = "banana-bread"
  vpc_cidr        = "10.123.0.0/16"
  dns_zone        = "aws.alleaffengaffen.ch"
  create_dns_zone = true # NS records still have to be added manually
  ingress_class   = "nginx"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

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

  tags = {
    Cluster    = "banana-bread"
    GithubRepo = "github.com/alleaffengaffen/banana-bread"
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
