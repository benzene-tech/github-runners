locals {
  name_prefix = "github-runners"
}

module "eks" {
  source  = "app.terraform.io/Benzene/eks/aws"
  version = "1.2.2"

  name_prefix                = local.name_prefix
  vpc_id                     = var.vpc_id
  update_aws_auth_config_map = true
  aws_auth_roles             = var.aws_auth_roles
  cluster_iam_role_name      = "BenzeneCluster"
  node_group_iam_role_name   = "BenzeneNodeGroup"
  node_groups = {
    runners = {
      subnet_type = "public"
      scaling = {
        desired_size = 1
        min_size     = 1
        max_size     = 3
      }
    }
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  for_each = toset(["edit", "view"])

  metadata {
    name = each.value
  }

  role_ref {
    name      = each.value
    kind      = "ClusterRole"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    name      = each.value
    kind      = "Group"
    api_group = "rbac.authorization.k8s.io"
  }
}
