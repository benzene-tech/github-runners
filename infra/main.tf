locals {
  name_prefix = "github-runners"
}

module "vpc" {
  source = "github.com/benzene-tech/vpc?ref=v1.0"

  name_prefix        = local.name_prefix
  vpc_cidr_block     = var.vpc_cidr_block
  enable_nat_gateway = false
}

module "eks" {
  source = "github.com/benzene-tech/eks?ref=v1.1"

  vpc_id                     = module.vpc.vpc_id
  name_prefix                = local.name_prefix
  update_aws_auth_config_map = true
  aws_auth_roles             = var.aws_auth_roles
  eks_cluster_iam_role_name  = "BenzeneEKS"
  node_group_iam_role_name   = "BenzeneNodeGroup"
  node_group_config = {
    subnet_type = "public"
    scaling = {
      desired_size = 1
      max_size     = 3
      min_size     = 1
    }
  }
}
