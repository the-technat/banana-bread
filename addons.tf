##########
# Argo CD
##########
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.x.x"
  namespace        = "argocd"
  create_namespace = true

  values = [
    "${file("helm_values/argocd_values.yaml")}"
  ]

  depends_on = [
    module.eks,
    helm_release.cilium
  ]
}

# module "eks_blueprints_kubernetes_addons" {
#   source = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons"

#   eks_cluster_id       = module.eks.cluster_name
#   eks_cluster_endpoint = module.eks.cluster_endpoint
#   eks_oidc_provider    = module.eks.oidc_provider
#   eks_cluster_version  = module.eks.cluster_version

#   # Wait on the `kube-system` profile before provisioning addons
#   data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

#   enable_amazon_eks_aws_ebs_csi_driver = true
#   enable_cluster_autoscaler            = true
#   enable_aws_load_balancer_controller  = true
#   enable_aws_node_termination_handler  = true
#   enable_cert_manager                  = true
#   enable_external_dns                  = true
#   enable_kyverno                       = true
#   enable_metrics_server                = true

#   tags = local.tags
# }
