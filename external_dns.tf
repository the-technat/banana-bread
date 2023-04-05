##########
# EKS Blueprints managed external-dns
##########
module "external_dns" {
  count  = 0
  source = "github.com/aws-ia/terraform-aws-eks-blueprints.git/modules/kubernetes-addons"


  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  # Wait on the node group(s) before provisioning addons
  data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

  enable_external_dns = true
  external_dns_route53_zone_arns = [
    "arn:aws:route53::${local.account_id}:hostedzone/Z1234567890"
  ]

  tags = local.tags

  depends_on = [
    module.eks
  ]
}
