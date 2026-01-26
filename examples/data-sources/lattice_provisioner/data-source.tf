provider "wirtual" {}

data "lattice_provisioner" "dev" {}

data "lattice_workspace" "dev" {}

resource "lattice_agent" "main" {
  arch = data.lattice_provisioner.dev.arch
  os   = data.lattice_provisioner.dev.os
  dir  = "/workspace"
  display_apps {
    vscode          = true
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }
}