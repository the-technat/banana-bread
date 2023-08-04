##########
# AWS Load Balancer Controller
##########
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.5.3"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/aws_load_balancer_controller.yaml", {
      region       = local.region
      cluster_name = local.cluster_name
      role_arn     = module.aws_load_balancer_controller_irsa.iam_role_arn
      vpcID        = module.vpc.vpc_id
    })
  ]

  depends_on = [
    argocd_application.cluster_autoscaler,
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

