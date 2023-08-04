##########
# Cluster-Autoscaler
##########
resource "argocd_application" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "argocd"
    labels    = {}
  }

  spec {
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace_v1.aws.metadata[0].name
    }

    source {
      repo_url        = "https://kubernetes.github.io/autoscaler"
      chart           = "cluster-autoscaler"
      target_revision = "9.29.0"
      helm {
        release_name = "cluster-autoscaler"
        value_files  = ["${path.module}/helm_values/cluster_autoscaler.yaml"]
        parameter {
          name  = "awsRegion"
          value = local.region
        }
        parameter {
          name  = "autoDiscovery.clusterName"
          value = local.cluster_name
        }
        parameter {
          name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          value = module.aws_cluster_autoscaler_irsa.iam_role_arn
        }
        parameter {
          name  = "autoDiscovery.tags.autoscaling/enabled"
          value = "foo"
        }
      }
    }
    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      sync_options = local.sync_options
      retry {
        limit = "5"
        backoff {
          duration     = "30s"
          max_duration = "2m"
          factor       = "2"
        }
      }
    }
  }

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra,
    kubernetes_namespace_v1.aws,
    module.aws_cluster_autoscaler_irsa,
  ]
}

resource "kubernetes_namespace_v1" "aws" {
  metadata {
    annotations = {}

    labels = {}

    name = "aws"
  }
}


module "aws_cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                 = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [local.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:cluster-autoscaler"]
    }
  }

  tags = local.tags
}
