data "lattice_workspace" "me" {}

resource "lattice_agent" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "/workspace"
}

resource "lattice_script" "dotfiles" {
  agent_id     = lattice_agent.dev.agent_id
  display_name = "Dotfiles"
  icon         = "/icon/dotfiles.svg"
  run_on_start = true
  script = templatefile("~/get_dotfiles.sh", {
    DOTFILES_URI : var.dotfiles_uri,
    DOTFILES_USER : var.dotfiles_user
  })
}

resource "lattice_script" "code-server" {
  agent_id           = lattice_agent.dev.agent_id
  display_name       = "code-server"
  icon               = "/icon/code.svg"
  run_on_start       = true
  start_blocks_login = true
  script = templatefile("./install-code-server.sh", {
    LOG_PATH : "/tmp/code-server.log"
  })
}

resource "lattice_script" "nightly_sleep_reminder" {
  agent_id     = lattice_agent.dev.agent_id
  display_name = "Nightly update"
  icon         = "/icon/database.svg"
  cron         = "0 22 * * *"
  script       = <<EOF
    #!/bin/sh
    echo "Running nightly update"
    sudo apt-get install
  EOF
}

resource "lattice_script" "shutdown" {
  agent_id     = lattice_agent.dev.id
  display_name = "Stop daemon server"
  run_on_stop  = true
  icon         = "/icons/memory.svg"
  script       = <<EOF
    #!/bin/sh 
    kill $(lsof -i :3002 -t) >/tmp/pid.log 2>&1 &
  EOF
}