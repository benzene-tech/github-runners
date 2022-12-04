locals {
  name_prefix = "github_runners"
}

module "vpc" {
  source = "github.com/SanthoshNath/VPC?ref=master"

  name_prefix    = local.name_prefix
  vpc_cidr_block = var.vpc_cidr_block
  additional_public_subnet_tags = {
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
  additional_private_subnet_tags = {
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  }
}

module "eks" {
  source = "github.com/SanthoshNath/EKS?ref=master"

  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix
  node_group_scaling_config = {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
    },
    github-runners = {
      name = local.name_prefix
      selectors = [
        {
          namespace = "actions-runner-system"
        }
      ]
    }
  }
}
