##########
# Contour
##########
resource "helm_release" "contour" {
  count = 0 # currently ingress-nginx is used as hubble has some problems with contour
  name             = "contour"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "contour"
  version          = "12.1.0"
  namespace        = "contour"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/contour.yaml", {
      acme_mail = local.acme_mail
      className = local.ingress_class
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra,
    helm_release.cert_manager
  ]
}
