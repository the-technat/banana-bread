##########
# Contour
##########
resource "helm_release" "contour" {
  name             = "contour"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "contour"
  version          = "11.x.x"
  namespace        = "contour"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/contour.yaml", {
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra
  ]
}
