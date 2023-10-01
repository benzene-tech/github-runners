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


# Helm
variable "enable_internal_load_balancer" {
  description = "Determine whether to enable or disable internal load balance"
  type        = string
  default     = false
  nullable    = false
}

variable "argo_cd_github_token" {
  description = "GitHub token to create credentials template in Argo CD"
  type        = string
  nullable    = false
  sensitive   = true
}
