##########
# Cert Manager
##########
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.12.1"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/cert_manager.yaml", {
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra
  ]
}

resource "helm_release" "cert_manager_extras" {
  name      = "cert-manager-extras"
  chart     = "${path.module}/charts/cert-manager-extras"
  namespace = "cert-manager"

  values = [
    templatefile("${path.module}/helm_values/cert_manager_extras.yaml", {
      mail  = local.acme_mail
      class = local.ingressClass
    })
  ]

  depends_on = [
    helm_release.cert_manager,
  ]
}
