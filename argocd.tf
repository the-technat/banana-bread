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
    "${file("${path.module}/helm_values/argocd.yaml")}"
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

resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "bcrypt_hash" "argo" {
  cleartext = random_password.argocd.result
}

resource "aws_secretsmanager_secret" "argocd" {
  name                    = "argocd"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}


data "aws_iam_policy_document" "argocd" {
  statement {
    sid    = "EnableAdminsToReadSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.cluster_admin_arns
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "argocd" {
  secret_arn = aws_secretsmanager_secret.argocd.arn
  policy     = data.aws_iam_policy_document.argocd.json
}
