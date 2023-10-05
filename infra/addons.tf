### Ingress
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


### Argo CD
resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "oci://ghcr.io/argoproj/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.root}/../argo-cd/values.yaml"),
    yamlencode({
      configs = {
        rbac = {
          "policy.csv" = <<-EOT
            %{for user in local.argo_cd_local_users~}
            g, ${user}, role:admin
            %{endfor~}
          EOT
        }
      }
    })
  ]

  set {
    name  = "configs.cm.url"
    value = local.argo_cd_url
  }

  dynamic "set_sensitive" {
    for_each = local.argo_cd_local_users

    content {
      name  = "configs.secret.extra.accounts\\.${set_sensitive.value}\\.password"
      value = random_password.argo_cd_local_user_passwords[set_sensitive.value].bcrypt_hash
    }
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientID"
    value = var.argo_cd_github_oauth_client_id
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientSecret"
    value = var.argo_cd_github_oauth_client_secret
  }

  dynamic "set" {
    for_each = local.argo_cd_local_users

    content {
      name  = "configs.cm.accounts\\.${set.value}"
      value = "login"
    }
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

resource "random_password" "argo_cd_local_user_passwords" {
  for_each = local.argo_cd_local_users

  length      = 32
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "argocd-local-user-passwords"
    namespace = "argocd"
  }

  data = { for user in local.argo_cd_local_users : user => random_password.argo_cd_local_user_passwords[user].result }

  depends_on = [helm_release.argo_cd]
}
