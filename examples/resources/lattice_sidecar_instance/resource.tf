resource "lattice_sidecar" "dev" {
  os   = "linux"
  arch = "amd64"
  auth = "google-instance-identity"
}

resource "google_compute_instance" "dev" {
  zone = "us-central1-a"
}

resource "lattice_sidecar_instance" "dev" {
  sidecar_id  = lattice_sidecar.dev.id
  instance_id = google_compute_instance.dev.instance_id
}
