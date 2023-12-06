module "eks" {
  source  = "app.terraform.io/Benzene/eks/aws"
  version = "1.3.0"

  name_prefix                = local.name_prefix
  vpc_id                     = var.vpc_id
  update_aws_auth_config_map = true
  aws_auth_roles             = var.aws_auth_roles
  cluster_iam_role_name      = "BenzeneCluster"
  node_group_iam_role_name   = "BenzeneNodeGroup"
  node_groups = {
    default = {
      subnet_type = "public"
      scaling = {
        desired_size = 1
        min_size     = 1
        max_size     = 1
      }
    }
  }
}
