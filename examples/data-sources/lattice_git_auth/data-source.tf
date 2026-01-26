provider "lattice" {}

data "lattice_git_auth" "github" {
  # Matches the ID of the git auth provider in Lattice.
  id = "github"
}

resource "lattice_sidecar" "dev" {
  os   = "linux"
  arch = "amd64"
  dir  = "~/wirtual"
  env = {
    GITHUB_TOKEN : data.lattice_git_auth.github.access_token
  }
  startup_script = <<EOF
if [ ! -d ~/wirtual ]; then
    git clone https://github.com/latticehq/lattice
fi
EOF
}