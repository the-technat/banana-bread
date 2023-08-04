##########
# Ingress-nginx
##########
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.7.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/ingress_nginx.yaml", {
      class = local.ingress_class
    })
  ]

  depends_on = [
    kubernetes_priority_class_v1.infra,
    argocd_application.cluster_autoscaler,
    helm_release.cert_manager,
  ]
}
