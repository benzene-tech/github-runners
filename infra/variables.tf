variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = null
}

variable "aws_auth_roles" {
  description = "AWS auth roles"
  type = list(object({
    username = string
    rolearn  = string
    groups   = list(string)
  }))
  default  = []
  nullable = false
}


### Helm
variable "external_dns_version" {
  description = "External DNS helm chart version"
  type        = string
  nullable    = false
}


variable "ingress_nginx_version" {
  description = "NGINX ingress helm chart version"
  type        = string
  nullable    = false
}

variable "enable_internal_load_balancer" {
  description = "Determine whether to enable or disable internal load balancer for NGINX ingress"
  type        = string
  default     = false
  nullable    = false
}


variable "argo_cd_version" {
  description = "Argo CD helm chart version"
  type        = string
  nullable    = false
}

variable "argo_cd_apps_version" {
  description = "Argo CD apps helm chart version"
  type        = string
  nullable    = false
}

variable "argo_cd_github_app_client_id" {
  description = "Argo CD GitHub app client ID"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "argo_cd_github_app_client_secret" {
  description = "Argo CD GitHub app client secret"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "argo_cd_github_token" {
  description = "GitHub token to create credentials template in Argo CD"
  type        = string
  nullable    = false
  sensitive   = true
}


### GitHub
variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App private key"
  type        = string
  nullable    = false
  sensitive   = true
}
