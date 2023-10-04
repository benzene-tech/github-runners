output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.name
}

output "argo_cd_url" {
  description = "Argo CD url"
  value       = local.argo_cd_url
}
