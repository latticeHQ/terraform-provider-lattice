data "lattice_agent" "me" {
}

resource "lattice_sidecar" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "/agent"
  display_apps {
    vscode          = true
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }

  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    script       = "lattice stat cpu"
    interval     = 10
    timeout      = 1
    order        = 2
  }
  metadata {
    display_name = "RAM Usage"
    key          = "ram_usage"
    script       = "lattice stat mem"
    interval     = 10
    timeout      = 1
    order        = 1
  }

  order = 1
}

resource "kubernetes_pod" "dev" {
  count = data.lattice_agent.me.start_count
  spec {
    container {
      command = ["sh", "-c", lattice_sidecar.dev.init_script]
      env {
        name  = "lattice_SIDECAR_TOKEN"
        value = lattice_sidecar.dev.token
      }
    }
  }
}
