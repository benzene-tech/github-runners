provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this[0].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this[0].token
}
