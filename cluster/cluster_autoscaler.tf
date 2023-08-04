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
        values = tostring(templatefile("${path.module}/helm_values/cluster_autoscaler.yaml", {
          cluster_name = local.cluster_name
          region       = local.region
          role_arn     = module.aws_cluster_autoscaler_irsa.iam_role_arn
          min_size     = local.min_node_size
          max_size     = local.max_node_size
          autoscaling_groups = flatten([
            for node_group_key, node_group in module.eks.eks_managed_node_groups : [
              node_group.node_group_autoscaling_group_names[*]
            ]
          ])
        }))
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
