module "addons" {
  source  = "app.terraform.io/Benzene/addons/helm"
  version = "1.0.0"

  argo_cd       = local.addons.argo_cd
  external_dns  = local.addons.external_dns
  ingress_nginx = local.addons.ingress_nginx
  karpenter     = local.addons.karpenter

  depends_on = [module.eks, aws_eks_pod_identity_association.this]
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = { for name, config in local.addons : name => config if lookup(config, "aws_role", null) != null }

  cluster_name    = module.eks.name
  service_account = replace(each.key, "_", "-")
  namespace       = each.value.namespace
  role_arn        = data.aws_iam_role.this[each.key].arn

  depends_on = [module.eks.addons]
}


### Argo CD
resource "github_actions_variable" "argo_cd_server_host" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_SERVER_HOST"
  value         = trimsuffix(trimprefix(yamldecode(one(module.addons.argo_cd.metadata[*].values)).configs.cm.url, "https://"), "/${local.argo_cd_uri}")
}

resource "github_actions_variable" "argo_cd_server_path" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_SERVER_PATH"
  value         = local.argo_cd_uri

  depends_on = [module.addons.argo_cd]
}

resource "github_actions_variable" "argo_cd_username" {
  repository    = local.github_repository
  variable_name = "ARGO_CD_USERNAME"
  value         = local.argo_cd_username

  depends_on = [module.addons.argo_cd]
}

resource "github_actions_secret" "this" {
  repository      = local.github_repository
  secret_name     = "ARGO_CD_PASSWORD"
  plaintext_value = random_password.argo_cd_local_user_password.result

  depends_on = [module.addons.argo_cd]
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
    url          = "${yamldecode(one(module.addons.argo_cd.metadata[*].values)).configs.cm.url}/api/webhook"
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
}

resource "helm_release" "argo_cd_applications" {
  for_each = { for name, config in module.addons : name => config if name != "argo_cd" && contains(keys(local.addons), name) }

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
              repoURL        = trimprefix(each.value.repository, "oci://")
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
}
