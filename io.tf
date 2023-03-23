variable "argocd_password" {
  sensitive   = true
  type        = string
  description = "Password for Argo CD admin user"
}
