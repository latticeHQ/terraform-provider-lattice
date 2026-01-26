data "lattice_agent" "me" {}

resource "lattice_sidecar" "dev" {
  os             = "linux"
  arch           = "amd64"
  dir            = "/agent"
  startup_script = <<EOF
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337
EOF
}

resource "lattice_app" "code-server" {
  sidecar_id   = lattice_sidecar.dev.id
  slug         = "code-server"
  display_name = "VS Code"
  icon         = "${data.lattice_agent.me.access_url}/icon/code.svg"
  url          = "http://localhost:13337"
  share        = "owner"
  subdomain    = false
  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "lattice_app" "vim" {
  sidecar_id   = lattice_sidecar.dev.id
  slug         = "vim"
  display_name = "Vim"
  icon         = "${data.lattice_agent.me.access_url}/icon/vim.svg"
  command      = "vim"
}
