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

##########
# Argo CD
##########
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.x.x"
  namespace        = "argocd"
  create_namespace = true

  values = [
    "${file("helm_values/argocd_values.yaml")}"
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt_hash.argo.id
  }

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra
  ]
}

resource "bcrypt_hash" "argo" {
  cleartext = var.argocd_password
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
    helm_release.argocd
  ]
}

##########
# AWS Load Balancer Controller
##########
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.4.6"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/awslbcon_values.yaml", {
      region       = local.region
      cluster_name = local.cluster_name
      role_arn     = module.lb_controller_irsa.iam_role_arn
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium
  ]
}


module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "aws-lb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}


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
    templatefile("${path.module}/helm_values/certmanager_values.yaml", {
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium
  ]
}
