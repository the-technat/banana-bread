##########
# external-dns
##########
resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = "1.13.0"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/external_dns.yaml", {
      region       = local.region
      cluster_name = local.cluster_name
      role_arn     = module.aws_external_dns_irsa.iam_role_arn
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    module.aws_external_dns_irsa
  ]
}

module "aws_external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix           = "external-dns"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:external-dns"]
    }
  }

  tags = local.tags
}

