resource "lattice_agent" "dev" {
  os   = "linux"
  arch = "amd64"
  auth = "google-instance-identity"
}

resource "google_compute_instance" "dev" {
  zone = "us-central1-a"
}

resource "lattice_agent_instance" "dev" {
  agent_id    = lattice_agent.dev.id
  instance_id = google_compute_instance.dev.instance_id
}
