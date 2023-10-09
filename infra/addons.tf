### Ingress
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [file("${path.root}/helm/nginx.yaml")]

  set {
    name  = "controller.service.internal.enabled"
    value = var.enable_internal_load_balancer
  }

  depends_on = [module.eks]
}


### Argo CD
resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "oci://ghcr.io/argoproj/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.root}/helm/argo-cd.yaml"),
    yamlencode({
      configs = {
        rbac = {
          "policy.csv" = <<-EOT
            g, ${local.argo_cd_username}, role:admin
          EOT
        }
      }
    })
  ]

  set {
    name  = "configs.cm.url"
    value = local.argo_cd_url
  }

  set {
    name  = "configs.cm.accounts\\.${local.argo_cd_username}"
    value = "login"
  }

  set_sensitive {
    name  = "configs.secret.extra.accounts\\.${local.argo_cd_username}\\.password"
    value = random_password.argo_cd_local_user_password.bcrypt_hash
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

resource "github_actions_variable" "this" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_USERNAME"
  value         = local.argo_cd_username
}

resource "github_actions_secret" "this" {
  repository      = local.github_repository
  secret_name     = "ARGO_CD_PASSWORD"
  plaintext_value = random_password.argo_cd_local_user_password.result
}

resource "random_password" "argo_cd_local_user_password" {
  length      = 32
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "github_repository_webhook" "this" {
  repository = local.github_repository

  configuration {
    url          = "${local.argo_cd_url}/api/webhook"
    content_type = "json"
    secret       = random_password.github_webhook_secret.result
  }

  events = ["push"]

  depends_on = [helm_release.argo_cd]
}

resource "random_password" "github_webhook_secret" {
  length      = 16
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}
