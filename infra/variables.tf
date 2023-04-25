variable "vpc_cidr_block" {
  description = "VPC CIDR"
  type        = string
  nullable    = false
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
