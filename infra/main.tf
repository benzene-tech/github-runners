module "eks" {
  source = "github.com/SanthoshNath/EKS?ref=master"

  vpc_cidr_block = var.vpc_cidr_block
  name_prefix    = "github_runners"
}
