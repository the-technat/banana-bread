module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons"

  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  # Wait on the `kube-system` profile before provisioning addons
  data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

  # Cilium
  enable_cilium           = true
  cilium_enable_wireguard = true
  cilium_helm_config = {
    values = [
      "${file("config/cilium.yaml")}"
    ]
  }

  # Argo CD
  enable_argocd = true
  argocd_helm_config = {
    # set_sensitive = [
    #   {
    #     name  = "configs.secret.argocdServerAdminPassword"
    #     value = bcrypt_hash.argo.id
    #   }
    # ]
  }
  argocd_manage_add_ons = true # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_applications = {
    # addons = {
    #   path               = "chart"
    #   repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
    #   add_on_application = true
    # }
    # workloads = {
    #   path               = "envs/dev"
    #   repo_url           = "https://github.com/aws-samples/eks-blueprints-workloads.git"
    #   add_on_application = false
    # }
  }

  # Keda
  enable_keda = true
  keda_helm_config = {
    values = [
      {
        name  = "serviceAccount.create"
        value = "false"
      }
    ]
  }

  # CSI
  enable_amazon_eks_aws_ebs_csi_driver = true

  # Cluster-autoscaler
  enable_cluster_autoscaler = true


  # Cert-Manager
  enable_cert_manager = true


  tags = local.tags
}
