##########
# Cluster-Autoscaler
##########
resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.29.0"
  namespace        = "aws"
  create_namespace = true

  values = [
    templatefile("${path.module}/helm_values/cluster_autoscaler.yaml", {
      region       = local.region
      role_arn     = module.aws_cluster_autoscaler_irsa.iam_role_arn
      cluster_name = local.cluster_name
    })
  ]

  depends_on = [
    module.eks,
    helm_release.cilium,
    kubernetes_priority_class_v1.infra,
    module.aws_cluster_autoscaler_irsa,
  ]
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

##########
# scale-in preventer
# See ./scale-in-preventer/README.md for more informations
##########
resource "aws_iam_role" "scale_in_preventer" {
  name = "scale-in-preventer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "scale_in_preventer" {
  name        = "scale-in-preventer"
  path        = "/"
  description = "Policy for aws lamda scale-in-preventer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow"
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sclae_in_preventer" {
  role       = aws_iam_role.scale_in_preventer.name
  policy_arn = aws_iam_policy.scale_in_preventer.arn
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/scale-in-preventer/"
  output_path = "${path.module}/scale-in-preventer.zip"
}

resource "aws_lambda_function" "scale_in_preventer" {
  filename      = "${path.module}/scale-in-preventer.zip"
  function_name = "scale-in-preventer"
  role          = aws_iam_role.scale_in_preventer.arn
  handler       = "main"
  timeout       = "60"
  runtime       = "go1.x"

  tags = local.tags
}
