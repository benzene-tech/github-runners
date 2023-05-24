data "aws_eks_cluster" "this" {
  name = module.eks.name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.name
}
