locals {
  name_prefix = "github-runners"
  url         = "https://github-runners.benzene.co.in"

  helm_releases = {
    external_dns = {
      repository = "https://kubernetes-sigs.github.io/external-dns"
      chart      = "external-dns"
      version    = var.external_dns_version
      namespace  = "kube-system"

      set = {
        policy = "sync"
      }

      set_list = {
        sources       = ["ingress"]
        domainFilters = [replace(replace(local.url, "/^(?:(?:https)?:\\/\\/)?\\S+?\\./", ""), "/(?:[\\/?]{1}\\S*)*/", "")]
      }
    }

    ingress_nginx = {
      repository = "https://kubernetes.github.io/ingress-nginx"
      chart      = "ingress-nginx"
      version    = var.ingress_nginx_version
      namespace  = "ingress-nginx"

      values_file_paths = ["${path.root}/helm/nginx.yaml"]

      set = {
        "controller.service.internal.enabled" = var.enable_internal_load_balancer
      }
    }
  }

  argo_cd_uri       = "argo-cd"
  argo_cd_username  = "benzene"
  github_repository = "github-runners"
}
