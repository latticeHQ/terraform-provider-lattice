provider "lattice" {}

data "lattice_agent" "me" {}

data "lattice_agent_owner" "me" {}

resource "lattice_sidecar" "dev" {
  arch = "amd64"
  os   = "linux"
  dir  = local.repo_dir
  env = {
    OIDC_TOKEN : data.lattice_agent_owner.me.oidc_access_token,
  }
}

# Add git credentials from lattice_agent_owner
resource "lattice_env" "git_author_name" {
  sidecar_id = lattice_sidecar.sidecar_id
  name       = "GIT_AUTHOR_NAME"
  value      = coalesce(data.lattice_agent_owner.me.full_name, data.lattice_agent_owner.me.name)
}

resource "lattice_env" "git_author_email" {
  sidecar_id = var.sidecar_id
  name       = "GIT_AUTHOR_EMAIL"
  value      = data.lattice_agent_owner.me.email
  count      = data.lattice_agent_owner.me.email != "" ? 1 : 0
}