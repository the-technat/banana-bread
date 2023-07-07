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
    argocd_project.apps
  ]
}


##########
# Argo CD
##########
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.36.1"
  namespace        = "argocd"
  create_namespace = true
  values = [
    templatefile("${path.module}/helm_values/argocd.yaml", {
      dns_zone = local.dns_zone
      class    = local.ingress_class
    })
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt_hash.argo.id
  }

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra,
  ]
}

resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "bcrypt_hash" "argo" {
  cleartext = random_password.argocd.result
}

resource "aws_secretsmanager_secret" "argocd" {
  name                    = "argocd_admin_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}

data "aws_iam_policy_document" "argocd" {
  statement {
    sid    = "EnableAdminsToReadSecret"
    effect = "Allow"

    # the assumed role can get the secret
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cluster_admin.arn]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "argocd" {
  secret_arn = aws_secretsmanager_secret.argocd.arn
  policy     = data.aws_iam_policy_document.argocd.json
}
