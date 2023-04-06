##########
# EKS Blueprints managed cluster-autoscaler
##########
module "cluster_autoscaler" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints.git/modules/kubernetes-addons"


  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  # Wait on the node group(s) before provisioning addons
  data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    namespace = "aws"
  }

  tags = local.tags

  depends_on = [
    module.eks
  ]
}