data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  count = var.aws_auth_config != null ? 1 : 0

  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  count = var.aws_auth_config != null ? 1 : 0

  name = module.eks.cluster_name
}
