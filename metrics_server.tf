##########
# Metrics Server
##########
resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.x.x"
  namespace        = "metrics-server"
  create_namespace = true
  values = [
    templatefile("${path.module}/helm_values/metrics_server.yaml", {
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra
  ]
}