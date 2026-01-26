terraform {
  required_providers {
    wirtual = {
      source = "wirtualdev/wirtual"
    }
  }
}

provider "google" {
  region = "us-central1"
}

data "lattice_workspace" "me" {}

resource "lattice_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  auth = "google-instance-identity"
}

data "google_compute_default_service_account" "default" {}

resource "google_compute_instance" "dev" {
  zone         = "us-central1-a"
  count        = data.lattice_workspace.me.start_count
  name         = "wirtual-${data.lattice_workspace.me.owner}-${data.lattice_workspace.me.name}"
  machine_type = "e2-medium"
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = lattice_agent.dev.init_script
}
