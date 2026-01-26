data "lattice_workspace" "dev" {
}

resource "kubernetes_pod" "dev" {
  count = data.lattice_workspace.dev.transition == "start" ? 1 : 0
}
