provider "wirtual" {}


data "lattice_external_auth" "github" {
  id = "github"
}

data "lattice_external_auth" "azure-identity" {
  id       = "azure-identiy"
  optional = true
}
