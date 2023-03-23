resource "kubernetes_priority_class_v1" "infra" {
  metadata {
    name = "infra"
  }

  value = 1000000000

  depends_on = [
    module.eks
  ]
}


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
    helm_release.cilium,
    kubernetes_priority_class_v1.infra
  ]
}


##########
# AWS Load Balancer Controller
##########
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.x.x"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/awslbcon_values.yaml", {
      region       = local.region
      cluster_name = local.cluster_name
      role_arn     = module.lb_controller_irsa.iam_role_arn
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium
  ]
}


module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "aws-lb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
