locals {
  name_prefix         = "github-runners"
  argo_cd_url         = "https://github-runners.benzene-tech.com/argo-cd"
  argo_cd_local_users = toset(["gha"])
}
