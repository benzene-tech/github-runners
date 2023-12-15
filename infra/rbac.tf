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
