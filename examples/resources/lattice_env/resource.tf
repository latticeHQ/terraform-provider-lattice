data "lattice_workspace" "me" {}

resource "lattice_agent" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "/workspace"
}

resource "lattice_env" "welcome_message" {
  agent_id = lattice_agent.dev.id
  name     = "WELCOME_MESSAGE"
  value    = "Welcome to your Lattice workspace!"
}

resource "lattice_env" "internal_api_url" {
  agent_id = lattice_agent.dev.id
  name     = "INTERNAL_API_URL"
  value    = "https://api.internal.company.com/v1"
}