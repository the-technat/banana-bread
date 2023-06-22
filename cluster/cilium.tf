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

resource "null_resource" "purge_kube_proxy" {
  triggers = {
    eks = module.eks.cluster_endpoint # only do this when the cluster changes (e.g create/recreate)
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name}
      curl -LO https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
      chmod 0755 ./kubectl
      ./kubectl -n kube-system delete daemonset kube-proxy --ignore-not-found 
    EOT
  }
}


resource "null_resource" "purge_aws_networking" {
  triggers = {
    eks = module.eks.cluster_endpoint # only do this when the cluster changes (e.g create/recreate)
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name}
      curl -LO https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
      chmod 0755 ./kubectl
      ./kubectl -n kube-system delete daemonset aws-node --ignore-not-found
    EOT
  }
}

resource "kubernetes_ingress_v1" "hubble_ingress" {
  count = 0 # https://github.com/cilium/hubble-ui/issues/452
  metadata {
    name      = "hubble-ui"
    namespace = "kube-system"
    annotations = {
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod-${local.ingress_class}"
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = local.ingress_class
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
    helm_release.cilium,
  ]
}
