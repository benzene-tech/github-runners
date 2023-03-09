locals {
  name_prefix = "github_runners"
}

module "vpc" {
  source = "github.com/benzene-tech/vpc?ref=v1.0"

  name_prefix    = local.name_prefix
  vpc_cidr_block = var.vpc_cidr_block
}

module "eks" {
  source = "github.com/benzene-tech/eks?ref=v1.0"

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
        },
        {
          namespace = "cert-manager"
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

resource "null_resource" "eksctl" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -L "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C .
      ./eksctl create iamidentitymapping --cluster ${module.eks.cluster_name} --region=${var.aws_region} --arn ${sensitive(data.aws_iam_role.iam_identity_mapping.arn)} --group system:masters --username GHA --no-duplicate-arns
    EOT
  }
}
