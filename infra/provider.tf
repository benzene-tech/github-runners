provider "aws" {
  region = "ap-south-1"
}

provider "kubernetes" {
  host                   = one(data.aws_eks_cluster.this[*].endpoint)
  cluster_ca_certificate = base64decode(one(data.aws_eks_cluster.this[*].certificate_authority[0].data))
  token                  = one(data.aws_eks_cluster_auth.this[*].token)
}
