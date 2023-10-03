output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.name
}

output "argo_cd_url" {
  description = "Argo CD url"
  value       = "https://${data.kubernetes_service.this.status[0].load_balancer[0].ingress[0].hostname}"
}
