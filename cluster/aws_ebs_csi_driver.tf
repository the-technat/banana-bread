###############
# AWS EBS CSI-Driver
##############
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn  = module.aws_ebs_csi_driver_irsa.iam_role_arn

  configuration_values = jsonencode({
  
  })

  tags = local.tags

  depends_on = [ 
    module.eks, 
    helm_release.cilium
   ]
}

resource "helm_release" "aws_ebs_csi_driver_extras" {
  name      = "aws-ebs-csi-driver-extras"
  chart     = "${path.module}/charts/aws-ebs-csi-driver-extras"
  namespace = "kube-system"

  values = [
    templatefile("${path.module}/helm_values/aws_ebs_csi_driver_extras.yaml", {
      type = "gp3"
      className = "gp3"
    })
  ]

  depends_on = [
    aws_eks_addon.aws_ebs_csi_driver,
  ]
}


module "aws_ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                       = "aws-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws:aws-ebs-csi-controller"]
    }
  }

  tags = local.tags
}