terraform {
  required_version = ">= 0.12"

  cloud {
    workspaces {
      name = "GitHub_Runners"
    }
  }
}
