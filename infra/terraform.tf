terraform {
  required_version = "~> 1.5"

  cloud {
    organization = "Benzene"

    workspaces {
      name = "GitHub-Runners"
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
