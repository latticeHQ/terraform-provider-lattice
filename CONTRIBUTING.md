# Contributing to Lattice Terraform Provider

## Prerequisites

- **Go** 1.22+
- **Terraform** 1.0+ (for acceptance tests)
- **Make** (build orchestration)

## Setup

```bash
git clone https://github.com/latticeHQ/terraform-provider-lattice.git
cd terraform-provider-lattice
make build
```

## Development

| Command | Description |
|---------|-------------|
| `make build` | Build the provider binary |
| `make testacc` | Run Terraform acceptance tests |
| `make test-integration` | Run integration tests |
| `make gen` | Generate provider documentation |
| `make fmt` | Format Terraform files |

## Branch Naming

- `feat/<description>` — new resources or data sources
- `fix/<description>` — bug fixes
- `refactor/<description>` — code restructuring
- `docs/<description>` — documentation changes

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(resource): add lattice_agent resource
fix(provider): resolve authentication issue
docs: update resource documentation
```

## Pull Requests

1. Fork the repo and create a feature branch from `develop`
2. Write or update tests for your changes
3. Run `make testacc` before submitting
4. Keep PRs focused — one resource or fix per PR
5. Run `make gen` if you changed resource schemas (updates generated docs)

## Architecture

```
main.go              # Plugin entry point
provider/            # Provider and resource implementations
  provider.go        # Main provider configuration
  *.go               # Resource and data source implementations
  *_test.go          # Unit tests
integration/         # Integration test suites
docs/                # Generated Terraform documentation
  resources/         # Resource docs
  data-sources/      # Data source docs
examples/            # Example Terraform configurations
scripts/
  docsgen/           # Documentation generation scripts
```

## Testing

**Acceptance tests** require a running Lattice Runtime instance. Set `LATTICE_URL` and `LATTICE_API_TOKEN` environment variables before running:

```bash
export LATTICE_URL="https://your-lattice-instance.com"
export LATTICE_API_TOKEN="your-token"
make testacc
```

## License

By contributing, you agree that your contributions will be licensed under the [MPL 2.0 License](LICENSE).
