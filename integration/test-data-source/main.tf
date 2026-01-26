terraform {
  required_providers {
    lattice = {
      source = "latticehq/lattice"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

// TODO: test lattice_external_auth and lattice_git_auth
// data lattice_external_auth "me" {}
// data lattice_git_auth "me" {}
data "lattice_provisioner" "me" {}
data "lattice_agent" "me" {}
data "lattice_agent_owner" "me" {}

locals {
  # NOTE: these must all be strings in the output
  output = {
    "provisioner.arch" : data.lattice_provisioner.me.arch,
    "provisioner.id" : data.lattice_provisioner.me.id,
    "provisioner.os" : data.lattice_provisioner.me.os,
    "agent.access_port" : tostring(data.lattice_agent.me.access_port),
    "agent.access_url" : data.lattice_agent.me.access_url,
    "agent.id" : data.lattice_agent.me.id,
    "agent.name" : data.lattice_agent.me.name,
    "agent.owner" : data.lattice_agent.me.owner,
    "agent.owner_email" : data.lattice_agent.me.owner_email,
    "agent.owner_groups" : jsonencode(data.lattice_agent.me.owner_groups),
    "agent.owner_id" : data.lattice_agent.me.owner_id,
    "agent.owner_name" : data.lattice_agent.me.owner_name,
    "agent.owner_oidc_access_token" : data.lattice_agent.me.owner_oidc_access_token,
    "agent.owner_session_token" : data.lattice_agent.me.owner_session_token,
    "agent.start_count" : tostring(data.lattice_agent.me.start_count),
    "agent.template_id" : data.lattice_agent.me.template_id,
    "agent.template_name" : data.lattice_agent.me.template_name,
    "agent.template_version" : data.lattice_agent.me.template_version,
    "agent.transition" : data.lattice_agent.me.transition,
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
