###############
# Cilium
##############
resource "helm_release" "cilium" {
  count      = local.cni_plugin == "cilium" ? 1 : 0
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.13.x"
  namespace  = "kube-system"
  wait       = true

  values = [
    templatefile("${path.module}/helm_values/cilium.yaml", {
      cluster_endpoint = trim(module.eks.cluster_endpoint, "https://")
    })
  ]

  depends_on = [
    module.eks.aws_eks_cluster,
    null_resource.purge_aws_networking,
  ]
}

resource "null_resource" "purge_aws_networking" {
  count = local.cni_plugin == "cilium" ? 1 : 0
  triggers = {
    eks = module.eks.cluster_endpoint # only do this when the cluster changes (e.g create/recreate)
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name}
      curl -LO https://dl.k8s.io/release/v1.25.8/bin/linux/amd64/kubectl
      chmod 0755 ./kubectl
      ./kubectl -n kube-system delete daemonset aws-node --ignore-not-found
    EOT
  }
}
