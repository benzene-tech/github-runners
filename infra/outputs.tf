output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.name
}

output "external_dns_version" {
  description = "External DNS helm chart version"
  value       = one(helm_release.this["external_dns"].metadata[*].version)
}

output "ingress_nginx_version" {
  description = "NGINX ingress helm chart version"
  value       = one(helm_release.this["ingress_nginx"].metadata[*].version)
}

output "argo_cd_version" {
  description = "Argo CD helm chart version"
  value       = one(helm_release.argo_cd.metadata[*].version)
}

output "argo_cd_apps_version" {
  description = "Argo CD apps helm chart version"
  value       = one(helm_release.argo_cd_applications["ingress_nginx"].metadata[*].version)
}

output "argo_cd_url" {
  description = "Argo CD url"
  value       = yamldecode(one(helm_release.argo_cd.metadata[*].values)).configs.cm.url
}
