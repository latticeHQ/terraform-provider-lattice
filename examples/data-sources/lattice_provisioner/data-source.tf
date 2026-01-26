provider "lattice" {}

data "lattice_provisioner" "dev" {}

data "lattice_agent" "dev" {}

resource "lattice_sidecar" "main" {
  arch = data.lattice_provisioner.dev.arch
  os   = data.lattice_provisioner.dev.os
  dir  = "/agent"
  display_apps {
    vscode          = true
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }
}