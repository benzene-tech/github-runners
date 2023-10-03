data "aws_eks_cluster" "this" {
  name = module.eks.name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.name
}

data "kubernetes_service" "this" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}
