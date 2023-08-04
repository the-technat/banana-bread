##########
# Cluster-Autoscaler
##########
resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.29.0"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/cluster_autoscaler.yaml", {
      region       = local.region
      role_arn     = module.aws_cluster_autoscaler_irsa.iam_role_arn
      cluster_name = local.cluster_name
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra,
    module.aws_cluster_autoscaler_irsa,
  ]
}

module "aws_cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                 = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [local.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:cluster-autoscaler"]
    }
  }

  tags = local.tags
}
