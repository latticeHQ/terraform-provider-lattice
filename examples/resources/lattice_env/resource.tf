data "lattice_agent" "me" {}

resource "lattice_sidecar" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "/agent"
}

resource "lattice_env" "welcome_message" {
  sidecar_id = lattice_sidecar.dev.id
  name       = "WELCOME_MESSAGE"
  value      = "Welcome to your Lattice agent!"
}

resource "lattice_env" "internal_api_url" {
  sidecar_id = lattice_sidecar.dev.id
  name       = "INTERNAL_API_URL"
  value      = "https://api.internal.company.com/v1"
}