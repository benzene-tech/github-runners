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
