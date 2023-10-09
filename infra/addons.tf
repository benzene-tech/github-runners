### External DNS
resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.external_dns_version
  namespace        = "kube-system"
  create_namespace = true

  set_list {
    name  = "sources"
    value = ["ingress"]
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set_list {
    name  = "domainFilters"
    value = [replace(replace(local.url, "/^(?:(?:https)?:\\/\\/)?\\S+?\\./", ""), "/(?:[\\/?]{1}\\S*)*/", "")]
  }

  depends_on = [module.eks]
}


### NGINX Ingress
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
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
  version          = var.argo_cd_version
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

  set_list {
    name  = "server.ingress.hosts"
    value = [trimprefix(local.url, "https://")]
  }

  set_list {
    name  = "server.ingress.paths"
    value = ["/${local.argo_cd_uri}"]
  }

  set {
    name  = "configs.cm.url"
    value = "${local.url}/${local.argo_cd_uri}"
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

  depends_on = [helm_release.external_dns, helm_release.ingress_nginx]
}

resource "github_actions_variable" "argo_cd_server" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_SERVER"
  value         = trimprefix(yamldecode(one(helm_release.argo_cd.metadata[*].values)).configs.cm.url, "https://")
}

resource "github_actions_variable" "argo_cd_username" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_USERNAME"
  value         = local.argo_cd_username

  depends_on = [helm_release.argo_cd]
}

resource "github_actions_secret" "this" {
  repository      = local.github_repository
  secret_name     = "ARGO_CD_PASSWORD"
  plaintext_value = random_password.argo_cd_local_user_password.result

  depends_on = [helm_release.argo_cd]
}

resource "random_password" "argo_cd_local_user_password" {
  length      = 32
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1

  depends_on = [helm_release.ingress_nginx]
}

resource "github_repository_webhook" "this" {
  repository = local.github_repository

  configuration {
    url          = "${yamldecode(one(helm_release.argo_cd.metadata[*].values)).configs.cm.url}/api/webhook"
    content_type = "json"
    secret       = random_password.github_webhook_secret.result
  }

  events = ["push"]
}

resource "random_password" "github_webhook_secret" {
  length      = 16
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1

  depends_on = [helm_release.ingress_nginx]
}
