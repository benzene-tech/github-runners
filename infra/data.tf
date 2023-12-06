data "aws_eks_cluster" "this" {
  name = module.eks.name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.name
}

data "aws_iam_role" "this" {
  for_each = merge(
    { for name, config in local.helm_releases : name => config if lookup(config, "aws_role", null) != null },
    {
      karpenter = {
        aws_role = "BenzeneKarpenterController"
      }
    }
  )

  name = each.value.aws_role
}
