terraform {
  required_version = ">= 0.12"

  cloud {
    organization = "Benzene"

    workspaces {
      name = "GitHub-Runners"
    }
  }
}
