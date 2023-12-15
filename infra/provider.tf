provider "aws" {
  region = "ap-south-1"
}

provider "kubernetes" {
  host                   = one(data.aws_eks_cluster.this[*].endpoint)
  cluster_ca_certificate = base64decode(one(data.aws_eks_cluster.this[*].certificate_authority[0].data))
  token                  = one(data.aws_eks_cluster_auth.this[*].token)
}

provider "helm" {
  kubernetes {
    host                   = one(data.aws_eks_cluster.this[*].endpoint)
    cluster_ca_certificate = base64decode(one(data.aws_eks_cluster.this[*].certificate_authority[0].data))
    token                  = one(data.aws_eks_cluster_auth.this[*].token)
  }
}

provider "github" {
  owner = "benzene-tech"

  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_private_key
  }
}
