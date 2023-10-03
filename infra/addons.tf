resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [file("${path.root}/../ingress/nginx.yaml")]

  set {
    name  = "controller.service.internal.enabled"
    value = var.enable_internal_load_balancer
  }

  depends_on = [module.eks]
}

resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "oci://ghcr.io/argoproj/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = "argocd"
  create_namespace = true

  values = [file("${path.root}/../argo-cd/values.yaml")]

  set {
    name  = "configs.cm.url"
    value = "https://${data.kubernetes_service.this.status[0].load_balancer[0].ingress[0].hostname}"
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientID"
    value = var.argo_cd_github_oauth_client_id
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientSecret"
    value = var.argo_cd_github_oauth_client_secret
  }

  set_sensitive {
    name  = "configs.secret.githubSecret"
    value = random_password.github_webhook_secret.result
  }

  set_sensitive {
    name  = "configs.credentialTemplates.github.password"
    value = var.argo_cd_github_token
  }

  depends_on = [module.eks]
}

resource "random_password" "github_webhook_secret" {
  length      = 16
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}