locals {
  name            = "banana_bread"
  cluster_version = "1.25"
  region          = "eu-central-2"

  instance_types = ["t3a.medium", "t3.medium"]
  min_size       = 0
  max_size       = 3
  desired_size   = 1
  ami_type       = "AL2_x86_64"

  vpc_cidr = "10.123.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::298410952490:user/banana"
      username = "banana"
      groups   = ["system:masters"]
    },
  ]


  tags = {
    Cluster    = local.name
    GithubRepo = "github.com/alleaffengaffen/banana_bread"
  }
}
