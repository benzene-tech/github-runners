terraform {
  required_version = "~> 1.5"

  cloud {
    organization = "Benzene"

    workspaces {
      name = "GitHub-Runners"
    }
  }
}
