data "lattice_agent" "dev" {
}

resource "kubernetes_pod" "dev" {
  count = data.lattice_agent.dev.transition == "start" ? 1 : 0
}
