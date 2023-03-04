module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons"

  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  # Wait on the `kube-system` profile before provisioning addons
  data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

  # Add-ons
  enable_cilium           = true
  cilium_enable_wireguard = true

  tags = local.tags
}
