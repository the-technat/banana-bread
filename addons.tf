###############
# Cilium
##############
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.12.5"
  namespace  = "kube-system"
  wait       = true

  values = [
    templatefile("${path.module}/helm_values/cilium.yaml", {
    })
  ]

  depends_on = [
    module.eks.aws_eks_cluster
  ]
}

##########
# AWS Load Balancer Controller
##########
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.4.6"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/aws_load_balancer_controller.yaml", {
      region       = local.region
      cluster_name = local.cluster_name
      role_arn     = module.aws_load_balancer_controller_irsa.iam_role_arn
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    module.aws_load_balancer_controller_irsa
  ]
}

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                       = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
