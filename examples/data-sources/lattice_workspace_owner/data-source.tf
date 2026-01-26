provider "lattice" {}

data "lattice_workspace" "me" {}

data "lattice_workspace_owner" "me" {}

resource "lattice_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  dir  = local.repo_dir
  env = {
    OIDC_TOKEN : data.lattice_workspace_owner.me.oidc_access_token,
  }
}

# Add git credentials from lattice_workspace_owner
resource "lattice_env" "git_author_name" {
  agent_id = lattice_agent.agent_id
  name     = "GIT_AUTHOR_NAME"
  value    = coalesce(data.lattice_workspace_owner.me.full_name, data.lattice_workspace_owner.me.name)
}

resource "lattice_env" "git_author_email" {
  agent_id = var.agent_id
  name     = "GIT_AUTHOR_EMAIL"
  value    = data.lattice_workspace_owner.me.email
  count    = data.lattice_workspace_owner.me.email != "" ? 1 : 0
}