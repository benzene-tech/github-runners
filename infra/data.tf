data "aws_eks_cluster" "this" {
  name = module.eks.name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.name
}

data "aws_iam_role" "this" {
  for_each = { for name, config in local.addons : name => config if lookup(config, "aws_role", null) != null }

  name = each.value.aws_role
}
