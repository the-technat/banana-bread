##########
# General
##########
resource "kubernetes_priority_class_v1" "infra" {
  metadata {
    name = "infra"
  }

  value = 1000000000

  depends_on = [
    module.eks
  ]
}

resource "argocd_project" "apps" {
  metadata {
    name      = "apps"
    namespace = "argocd"
  }
  spec {
    source_repos = ["*"]
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "*"
    }
    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }

  depends_on = [
    module.eks,
    helm_release.cilium,
    helm_release.argocd
  ]
}

resource "argocd_application" "app_of_apps" {
  metadata {
    name      = "app-of-apps"
    namespace = "argocd"
  }

  wait = true

  spec {
    project = "apps"

    source {
      repo_url        = "https://github.com/alleaffengaffen/banana-bread.git"
      path            = "apps/configs"
      target_revision = "HEAD"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "argocd"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      sync_options = ["CreateNamespace=true", "ServerSideApply=true"]
      retry {
        limit = "5"
        backoff {
          duration     = "5s"
          max_duration = "2m"
          factor       = "2"
        }
      }
    }
  }

  depends_on = [
    module.eks,
    helm_release.cilium,
    helm_release.argocd,
    module.eks.aws_eks_cluster
  ]
}

