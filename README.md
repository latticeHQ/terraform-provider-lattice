<div align="center">

# Terraform Provider for Lattice

### Infrastructure as code for Lattice deployments

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-blue.svg?style=flat-square)](./LICENSE)
[![Go](https://img.shields.io/badge/Go-1.24+-00ADD8?style=flat-square&logo=go)](https://go.dev)

**Declare Lattice infrastructure. Apply. Done.**

[Lattice Runtime](https://github.com/latticeHQ/latticeRuntime) · [Terraform Registry](https://registry.terraform.io/providers/latticeHQ/lattice) · [Discussions](https://github.com/latticeHQ/latticeRuntime/discussions)

</div>

---

## What It Does

Manage Lattice Runtime resources — organizations, agents, templates, budgets, policies — as Terraform configuration.

```hcl
provider "lattice" {
  url   = "https://lattice.yourcompany.com"
  token = var.lattice_token
}

resource "lattice_agent" "worker" {
  name     = "data-processor"
  template = "default"
  budget   = 100  # USD/month hard cap
}
```

## Install

```bash
terraform {
  required_providers {
    lattice = {
      source  = "latticeHQ/lattice"
      version = "~> 0.1"
    }
  }
}
```

## Part of the Lattice Ecosystem

| Component | Role |
|-----------|------|
| [**Runtime**](https://github.com/latticeHQ/latticeRuntime) | Crash-proof runtime — identity, auth, audit, budget, mesh |
| [**Workbench**](https://github.com/latticeHQ/latticeWorkbench) | 316K-line multi-model agent workspace |
| **Terraform Provider** (this repo) | Infrastructure as code for Lattice |

---

<div align="center">

**[latticeruntime.com](https://latticeruntime.com)** — Crash-proof governed runtime for AI agents.

</div>
