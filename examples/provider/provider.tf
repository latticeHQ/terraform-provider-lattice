terraform {
  required_providers {
    lattice = {
      source = "latticehq/lattice"
    }
  }
}

provider "google" {
  region = "us-central1"
}

data "lattice_agent" "me" {}

resource "lattice_sidecar" "dev" {
  arch = "amd64"
  os   = "linux"
  auth = "google-instance-identity"
}

data "google_compute_default_service_account" "default" {}

resource "google_compute_instance" "dev" {
  zone         = "us-central1-a"
  count        = data.lattice_agent.me.start_count
  name         = "lattice-${data.lattice_agent.me.owner}-${data.lattice_agent.me.name}"
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
  metadata_startup_script = lattice_sidecar.dev.init_script
}
