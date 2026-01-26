terraform {
  required_providers {
    wirtual = {
      source = "wirtualdev/wirtual"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

data "lattice_workspace" "me" {}

resource "lattice_agent" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "/workspace"
}

resource "lattice_app" "hidden" {
  agent_id = lattice_agent.dev.id
  slug     = "hidden"
  share    = "owner"
  hidden   = true
}

resource "lattice_app" "visible" {
  agent_id = lattice_agent.dev.id
  slug     = "visible"
  share    = "owner"
  hidden   = false
}

resource "lattice_app" "defaulted" {
  agent_id = lattice_agent.dev.id
  slug     = "defaulted"
  share    = "owner"
}

locals {
  # NOTE: these must all be strings in the output
  output = {
    "lattice_app.hidden.hidden"    = tostring(lattice_app.hidden.hidden)
    "lattice_app.visible.hidden"   = tostring(lattice_app.visible.hidden)
    "lattice_app.defaulted.hidden" = tostring(lattice_app.defaulted.hidden)
  }
}

variable "output_path" {
  type = string
}

resource "local_file" "output" {
  filename = var.output_path
  content  = jsonencode(local.output)
}

output "output" {
  value     = local.output
  sensitive = true
}

