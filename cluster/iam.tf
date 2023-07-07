resource "aws_iam_policy" "cluster_admin" {
  name        = "EKSClusterAdminPolicy"
  path        = "/"
  description = "All permissions an EKS cluster admin needs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:*",
          "ec2:*",
          "vpc:*",
          "kms:*",
          "cloudwatch:*",
          "logs:*",
          "ssm:*",
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_admin" {
  role       = aws_iam_role.cluster_admin.name
  policy_arn = aws_iam_policy.cluster_admin.arn
}

resource "aws_iam_role" "cluster_admin" {
  name               = "EKSClusterAdmin"
  assume_role_policy = data.aws_iam_policy_document.cluster_admin_assume.json
}

data "aws_iam_policy_document" "cluster_admin_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    dynamic "principals" {
      for_each = local.cluster_admins
      content {
        type        = "AWS"
        identifiers = [principals.value["userarn"]]
      }
    }
  }
}

