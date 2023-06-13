###############
# Cilium
##############
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.13.3"
  namespace  = "kube-system"
  wait       = true
  timeout    = 3600

  values = [
    templatefile("${path.module}/helm_values/cilium.yaml", {
      cluster_endpoint = trim(module.eks.cluster_endpoint, "https://") # would be used for kube-proxy replacement
    })
  ]

  depends_on = [
    module.eks.aws_eks_cluster,
    null_resource.purge_aws_networking,
  ]
}

resource "null_resource" "purge_aws_networking" {
  count = 0
  triggers = {
    eks = module.eks.cluster_endpoint # only do this when the cluster changes (e.g create/recreate)
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name}
      curl -LO https://dl.k8s.io/release/v1.25.8/bin/linux/amd64/kubectl
      chmod 0755 ./kubectl
      ./kubectl -n kube-system delete daemonset aws-node --ignore-not-found
    EOT
  }
}

resource "kubernetes_ingress_v1" "hubble_ingress" {
  metadata {
    name = "hubble-ui"
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "hubble.${local.dns_zone}"
      http {
        path {
          backend {
            service {
              name = "hubble-ui"
              port {
                number = 80
              }
            }
          }

          path = "/"
        }
      }
    }

    tls {
      hosts       = ["hubble.${local.dns_zone}"]
      secret_name = "hubble-ui-tls"
    }
  }

  depends_on = [
    helm_release.ingress_nginx,
  ]
}
