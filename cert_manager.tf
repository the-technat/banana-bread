##########
# Cert Manager
##########
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.11.x"
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

resource "kubernetes_manifest" "clusterissuer_le_prod" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
    }
    "spec" = {
      "acme" = {
        "email" = "banane@alleaffengaffen.ch"
        "privatekeysecretref" = {
          "name" = "letsencrypt-prod"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "contour"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}


resource "kubernetes_manifest" "clusterissuer_le_staging" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-staging"
    }
    "spec" = {
      "acme" = {
        "email" = "banane@alleaffengaffen.ch"
        "privatekeysecretref" = {
          "name" = "letsencrypt-staging"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "contour"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

