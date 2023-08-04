resource "aws_iam_role_policy_attachment" "account_admin" {
  role       = aws_iam_role.cluster_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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

