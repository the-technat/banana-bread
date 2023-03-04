locals {
  name            = "banana_bread"
  cluster_version = "1.25"
  region          = "eu-central-2"

  instance_types = ["t3.micro", "t2.micro"]
  min_size       = 0
  max_size       = 3
  desired_size   = 1
  ami_type       = "BOTTLEROCKET_x86_64"
  platform       = "bottlerocket"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Cluster    = local.name
    GithubRepo = "github.com/alleaffengaffen/banana_bread"
  }
}
