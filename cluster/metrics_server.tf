##########
# Metrics Server
##########
resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.10.0"
  namespace        = "metrics-server"
  create_namespace = true
  values = [
    templatefile("${path.module}/helm_values/metrics_server.yaml", {
    })
  ]

  depends_on = [
    argocd_application.cluster_autoscaler,
  ]
}
