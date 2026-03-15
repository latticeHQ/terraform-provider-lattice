<div align="center">

# Terraform Provider for Lattice

### Infrastructure as code for Lattice Runtime deployments

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-blue.svg?style=flat-square)](./LICENSE)

**Declare your agent infrastructure. Lattice enforces it.**

[Lattice Runtime](https://github.com/latticeHQ/latticeRuntime) · [Lattice Registry](https://github.com/latticeHQ/latticeRegistry) · [Discussions](https://github.com/latticeHQ/latticeRuntime/discussions)

</div>

---

## Why a Terraform Provider

[Lattice Runtime](https://github.com/latticeHQ/latticeRuntime) is the open-source coordination layer for institutional AI — identity, authorization, audit, and budget for every agent in the organization. The Terraform Provider is how you declare and manage that infrastructure as code.

Agent infrastructure should be versioned, reviewed, and reproducible — the same way application infrastructure is. The Lattice Terraform Provider translates declarative HCL configurations into Runtime API calls, enabling:

- **Version-controlled agent deployments** — agent configurations live in git, not click-ops
- **Reproducible environments** — `terraform apply` produces identical coordination layer setups every time
- **Policy-as-code integration** — agent authorization, budget constraints, and audit rules declared alongside infrastructure
- **CI/CD pipelines** — automate agent lifecycle as part of your deployment pipeline

## Part of the Lattice Ecosystem

| Component | Role | Repository |
|-----------|------|------------|
| [**Enterprise**](https://github.com/latticeHQ/latticeEnterprise) | Enterprise administration and governance | Coming soon |
| [**Homebrew**](https://github.com/latticeHQ/latticeHomebrew) | One-line install on macOS and Linux | [latticeHomebrew](https://github.com/latticeHQ/latticeHomebrew) |
| [**Inference**](https://github.com/latticeHQ/latticeInference) | Local AI serving — MLX on Apple Silicon, zero-config clustering | [latticeInference](https://github.com/latticeHQ/latticeInference) |
| [**Operator**](https://github.com/latticeHQ/latticeOperator) | Self-hosted deployment management for Lattice infrastructure | [latticeOperator](https://github.com/latticeHQ/latticeOperator) |
| [**Public**](https://github.com/latticeHQ/lattice) | Website + binary releases | [lattice](https://github.com/latticeHQ/lattice) |
| [**Registry**](https://github.com/latticeHQ/latticeRegistry) | Community ecosystem — Terraform modules, templates, stacks | [latticeRegistry](https://github.com/latticeHQ/latticeRegistry) |
| [**Runtime**](https://github.com/latticeHQ/latticeRuntime) | Coordination layer — identity, authorization, audit, budget | [latticeRuntime](https://github.com/latticeHQ/latticeRuntime) |
| [**SDK**](https://github.com/latticeHQ/latticeSDK) | Go SDK for building Department Stacks | [latticeSDK](https://github.com/latticeHQ/latticeSDK) |
| **Terraform Provider** (this repo) | Infrastructure as code for Lattice deployments | You are here |
| [**Toolbox**](https://github.com/latticeHQ/latticeToolbox) | macOS app manager for Lattice products | [latticeToolbox](https://github.com/latticeHQ/latticeToolbox) |
| [**Workbench**](https://github.com/latticeHQ/latticeWorkbench) | Reference Engineering Stack — multi-model agent workspace | [latticeWorkbench](https://github.com/latticeHQ/latticeWorkbench) |

---

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

<div align="center">

**[latticeruntime.com](https://latticeruntime.com)** — The open-source coordination layer for institutional AI.

</div>
