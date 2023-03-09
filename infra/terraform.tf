terraform {
  required_version = ">= 0.12"

  cloud {
    organization = "Benzene"

    workspaces {
      name = "GitHub-Runners"
    }
  }

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
