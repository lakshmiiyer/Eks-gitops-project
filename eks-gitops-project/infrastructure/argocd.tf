# 1. Create a dedicated namespace for GitOps operations
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# 2. Deploy ArgoCD using the official Helm Chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "7.1.3" # Locked to a stable version

  # Custom values overrides for a secure, modern installation
  values = [
    yamlencode({
      server = {
        # Allows accessing the UI without SSL certificate warning blocks in dev
        insecure = true
      }
    })
  ]
}