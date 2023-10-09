output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.name
}

output "argo_cd_url" {
  description = "Argo CD url"
  value       = yamldecode(one(helm_release.argo_cd.metadata[*].values)).configs.cm.url
}
