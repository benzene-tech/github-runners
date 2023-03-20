variable "aws_region" {
  description = "AWS region"
  type        = string
  nullable    = false
}

variable "vpc_cidr_block" {
  description = "VPC CIDR"
  type        = string
  nullable    = false
}

variable "aws_auth_config" {
  description = "AWS auth config map to be attached to EKS. Map should be USERNAME = ROLE_NAME"
  type        = map(string)
  default     = null
}
