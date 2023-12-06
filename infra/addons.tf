resource "aws_eks_pod_identity_association" "this" {
  for_each = merge(
    { for name, config in local.helm_releases : name => config if lookup(config, "aws_role", null) != null },
    {
      karpenter = {
        namespace = "kube-system"
      }
    }
  )

  cluster_name    = module.eks.name
  service_account = replace(each.key, "_", "-")
  namespace       = each.value.namespace
  role_arn        = data.aws_iam_role.this[each.key].arn

  depends_on = [module.eks.addons]
}


resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.33.0"
  namespace        = "kube-system"
  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = module.eks.name
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [module.eks, aws_eks_pod_identity_association.this]
}


resource "helm_release" "this" {
  for_each = local.helm_releases

  name             = replace(each.key, "_", "-")
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = true

  values = toset([for file_path in lookup(each.value, "values_file_paths", []) : file(file_path)])

  dynamic "set" {
    for_each = lookup(each.value, "set", {})

    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_list" {
    for_each = lookup(each.value, "set_list", {})

    content {
      name  = set_list.key
      value = set_list.value
    }
  }

  dynamic "set_sensitive" {
    for_each = lookup(each.value, "set_sensitive", {})

    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  depends_on = [helm_release.karpenter]
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
            p, role:readwrite, applications, create, */*, allow
            p, role:readwrite, applications, update, */*, allow
            p, role:readwrite, applications, delete, */*, allow
            p, role:readwrite, applications, sync, */*, allow
            p, role:readwrite, applications, override, */*, allow
            p, role:readwrite, applications, action/*, */*, allow
            p, role:readwrite, applicationsets, get, */*, allow
            p, role:readwrite, applicationsets, create, */*, allow
            p, role:readwrite, applicationsets, update, */*, allow
            p, role:readwrite, applicationsets, delete, */*, allow
            p, role:readwrite, certificates, create, *, allow
            p, role:readwrite, certificates, update, *, allow
            p, role:readwrite, certificates, delete, *, allow
            p, role:readwrite, clusters, create, *, allow
            p, role:readwrite, clusters, update, *, allow
            p, role:readwrite, clusters, delete, *, allow
            p, role:readwrite, repositories, create, *, allow
            p, role:readwrite, repositories, update, *, allow
            p, role:readwrite, repositories, delete, *, allow
            p, role:readwrite, projects, create, *, allow
            p, role:readwrite, projects, update, *, allow
            p, role:readwrite, projects, delete, *, allow
            p, role:readwrite, accounts, update, *, allow
            p, role:readwrite, gpgkeys, create, *, allow
            p, role:readwrite, gpgkeys, delete, *, allow

            %{~for helm_release in helm_release.this~}
            p, role:readwrite, applications, create, default/${one(helm_release.metadata[*].name)}, deny
            p, role:readwrite, applications, update, default/${one(helm_release.metadata[*].name)}, deny
            p, role:readwrite, applications, delete, default/${one(helm_release.metadata[*].name)}, deny
            p, role:readwrite, applications, sync, default/${one(helm_release.metadata[*].name)}, deny
            p, role:readwrite, applications, override, default/${one(helm_release.metadata[*].name)}, deny
            %{~endfor~}

            g, role:readwrite, role:readonly
            g, ${local.argo_cd_username}, role:readwrite
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

  dynamic "set" {
    for_each = toset(["basehref", "rootpath"])

    content {
      name  = "configs.params.server\\.${set.value}"
      value = "/${local.argo_cd_uri}"
    }
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
    value = var.argo_cd_github_app_client_id
  }

  set_sensitive {
    name  = "configs.secret.extra.dex\\.github\\.clientSecret"
    value = var.argo_cd_github_app_client_secret
  }

  set_sensitive {
    name  = "configs.secret.githubSecret"
    value = random_password.github_webhook_secret.result
  }

  set_sensitive {
    name  = "configs.credentialTemplates.github.password"
    value = var.argo_cd_github_token
  }
}

resource "github_actions_variable" "argo_cd_server_host" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_SERVER_HOST"
  value         = trimsuffix(trimprefix(yamldecode(one(helm_release.argo_cd.metadata[*].values)).configs.cm.url, "https://"), "/${local.argo_cd_uri}")
}

resource "github_actions_variable" "argo_cd_server_path" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_SERVER_PATH"
  value         = local.argo_cd_uri
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

  depends_on = [helm_release.this["ingress_nginx"]]
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

  depends_on = [helm_release.this["ingress_nginx"]]
}

resource "helm_release" "argo_cd_applications" {
  for_each = helm_release.this

  name             = each.value.name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = var.argo_cd_apps_version
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      applications = [
        {
          name      = each.value.name
          namespace = "argocd"
          project   = "default"
          syncPolicy = {
            syncOptions = ["ApplyOutOfSyncOnly=true", "RespectIgnoreDifferences=true"]
          }
          sources = [
            {
              repoURL        = each.value.repository
              chart          = each.value.chart
              targetRevision = each.value.version
              helm = {
                releaseName = each.value.name
                values      = yamlencode(jsondecode(one(each.value.metadata[*].values)))
              }
            }
          ]
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = each.value.namespace
          }
          ignoreDifferences = [
            {
              group        = "*"
              kind         = "*"
              jsonPointers = ["/metadata/labels", "/spec"]
            }
          ]
        }
      ]
    })
  ]

  depends_on = [helm_release.argo_cd]
}
