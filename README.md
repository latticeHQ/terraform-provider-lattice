# Terraform Provider for Lattice

Terraform provider for [Lattice Runtime](https://github.com/latticeHQ/latticeRuntime) — the open-source coordination layer for institutional AI.

## Part of the Lattice Ecosystem

| Component | Role | Repository |
|-----------|------|------------|
| [**Homebrew**](https://github.com/latticeHQ/latticeHomebrew) | One-line install on macOS and Linux | [latticeHomebrew](https://github.com/latticeHQ/latticeHomebrew) |
| [**Inference**](https://github.com/latticeHQ/latticeInference) | Local AI serving — MLX on Apple Silicon, zero-config clustering | [latticeInference](https://github.com/latticeHQ/latticeInference) |
| [**Public**](https://github.com/latticeHQ/lattice) | Website + binary releases | [lattice](https://github.com/latticeHQ/lattice) |
| [**Registry**](https://github.com/latticeHQ/latticeRegistry) | Community ecosystem — Terraform modules, templates, stacks | [latticeRegistry](https://github.com/latticeHQ/latticeRegistry) |
| [**Runtime**](https://github.com/latticeHQ/latticeRuntime) | Coordination layer — identity, authorization, audit, budget | [latticeRuntime](https://github.com/latticeHQ/latticeRuntime) |
| **Terraform Provider** (this repo) | Infrastructure as code for Lattice deployments | You are here |
| [**Toolbox**](https://github.com/latticeHQ/latticeToolbox) | macOS app manager for Lattice products | [latticeToolbox](https://github.com/latticeHQ/latticeToolbox) |
| [**Workbench**](https://github.com/latticeHQ/latticeWorkbench) | Reference Engineering Stack — multi-model agent workspace | [latticeWorkbench](https://github.com/latticeHQ/latticeWorkbench) |

## Developing

### Prerequisites

- [Go](https://golang.org/doc/install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

We recommend using [`nix`](https://nixos.org/download.html) to manage your development environment. If you have `nix` installed, you can run `nix develop` to enter a shell with all the necessary dependencies.

### Building

Follow the instructions outlined in the [Terraform documentation](https://developer.hashicorp.com/terraform/cli/config/config-file#development-overrides-for-provider-developers)
to setup your local Terraform to use your local version rather than the registry version.

1. Create a file named `.terraformrc` in your `$HOME` directory
2. Add the following content:

   ```hcl
    provider_installation {
        dev_overrides {
          "latticehq/lattice" = "/path/to/terraform-provider-lattice"
        }

        direct {}
    }
   ```

3. (optional, but recommended) Validate your configuration:
   1. Create a new `main.tf` file and include:
   ```hcl
   terraform {
       required_providers {
           lattice = {
               source = "latticehq/lattice"
           }
       }
   }
   ```
   2. Run `terraform init` and observe a warning like `Warning: Provider development overrides are in effect`
4. Run `go build -o terraform-provider-lattice` to build the provider binary
5. All local Terraform runs will now use your local provider!
6. _**NOTE**: we vendor in this provider into `github.com/latticehq/latticeRuntime`, so if you're testing with a local clone then you should also run `go mod edit -replace github.com/latticehq/terraform-provider-lattice=/path/to/terraform-provider-lattice` in your clone._

### Terraform Acceptance Tests

To run Terraform acceptance tests, run `make testacc`. This will test the provider against the locally installed version of Terraform.

> **Note:** our [CI workflow](./github/workflows/test.yml) runs a test matrix against multiple Terraform versions.

### Integration Tests

The tests under the `./integration` directory perform the following steps:

- Build the local version of the provider,
- Run an in-memory Lattice instance with a specified version,
- Validate the behaviour of the local provider against that specific version of Lattice.

To run these integration tests locally:

1. Pull the version of the Lattice image you wish to test:

   ```console
     docker pull docker.io/onchainengineer/lattice:main-x.y.z-devel-abcd1234
   ```

1. Run `lattice_VERSION=main-x.y.z-devel-abcd1234 make test-integration`.

> **Note:** you can specify `lattice_IMAGE` if the Lattice image you wish to test is hosted somewhere other than `docker.io/onchainengineer/lattice`.

## License

MPL 2.0

---

**[latticeruntime.com](https://latticeruntime.com)**
