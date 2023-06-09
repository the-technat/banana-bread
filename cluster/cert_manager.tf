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

resource "null_resource" "cert_manager_issuers" {
  triggers = {
    cert_manager = helm_release.cert_manager.metadata[0].values
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name}
      curl -LO https://dl.k8s.io/release/v1.25.8/bin/linux/amd64/kubectl
      chmod 0755 ./kubectl
      ./kubectl -n cert-manager apply -f "${path.module}/helm_values/cert_manager_issuers.yaml"
    EOT
  }
}

