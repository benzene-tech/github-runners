locals {
  name_prefix       = "github-runners"
  url               = "https://github-runners.benzene.co.in"
  argo_cd_uri       = "argo-cd"
  argo_cd_username  = "benzene"
  github_repository = "github-runners"

  eks_addons = {
    aws-eks-pod-identity-agent = {
      version = "v1.0.0-eksbuild.1"
    }
  }

  addons = {
    karpenter = {
      version   = var.karpenter_version
      namespace = "kube-system"
      aws_role  = "BenzeneKarpenterController"

      values = [file("${path.root}/helm/karpenter.yaml")]

      set = {
        "settings.clusterName" = module.eks.name
      }
    }

    external_dns = {
      version   = var.external_dns_version
      namespace = "kube-system"
      aws_role  = "BenzeneExternalDNSController"

      set = {
        policy = "sync"
      }

      set_list = {
        sources       = ["ingress"]
        domainFilters = [replace(replace(local.url, "/^(?:(?:https)?:\\/\\/)?\\S+?\\./", ""), "/(?:[\\/?]{1}\\S*)*/", "")]
      }
    }

    ingress_nginx = {
      version   = var.ingress_nginx_version
      namespace = "ingress-nginx"

      values = [file("${path.root}/helm/nginx.yaml")]

      set = {
        "controller.service.internal.enabled" = var.enable_internal_load_balancer
      }
    }

    argo_cd = {
      version   = var.argo_cd_version
      namespace = "argocd"

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

                %{~for addon in ["karpenter", "external-dns", "ingress-nginx"]~}
                p, role:readwrite, applications, create, default/${addon}, deny
                p, role:readwrite, applications, update, default/${addon}, deny
                p, role:readwrite, applications, delete, default/${addon}, deny
                p, role:readwrite, applications, sync, default/${addon}, deny
                p, role:readwrite, applications, override, default/${addon}, deny
                %{~endfor~}

                g, role:readwrite, role:readonly
                g, ${local.argo_cd_username}, role:readwrite
              EOT
            }
          }
        })
      ]

      set = {
        "configs.cm.url"                                  = "${local.url}/${local.argo_cd_uri}"
        "configs.params.server\\.basehref"                = "/${local.argo_cd_uri}"
        "configs.params.server\\.rootpath"                = "/${local.argo_cd_uri}"
        "configs.cm.accounts\\.${local.argo_cd_username}" = "login"
      }

      set_list = {
        "server.ingress.hosts" = [trimprefix(local.url, "https://")]
        "server.ingress.paths" = ["/${local.argo_cd_uri}"]
      }

      set_sensitive = {
        "configs.secret.extra.accounts\\.${local.argo_cd_username}\\.password" = random_password.argo_cd_local_user_password.bcrypt_hash
        "configs.secret.extra.dex\\.github\\.clientID"                         = var.argo_cd_github_app_client_id
        "configs.secret.extra.dex\\.github\\.clientSecret"                     = var.argo_cd_github_app_client_secret
        "configs.secret.githubSecret"                                          = random_password.github_webhook_secret.result
        "configs.credentialTemplates.github.password"                          = var.argo_cd_github_token
      }
    }
  }
}
