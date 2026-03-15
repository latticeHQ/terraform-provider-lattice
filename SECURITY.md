# Security Policy

## Reporting Security Vulnerabilities

**Do not report security vulnerabilities through public GitHub issues.**

Instead, please report them privately to:

**Email:** security@latticeruntime.com

Include the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will respond within 48 hours and work with you to understand and address the issue.

## Scope

This security policy covers the **Lattice Terraform Provider**, including:

- Provider authentication and credential handling
- API communication with Lattice Runtime
- Resource and data source implementations
- State file handling and sensitive data management

## What Qualifies as a Security Issue?

Issues that could compromise:

- **Credential exposure** — API tokens or secrets leaked in state files, logs, or plan output
- **Authentication bypass** — provider operating without proper Runtime authentication
- **State manipulation** — unauthorized modification of Terraform state
- **Injection attacks** — user input flowing unsanitized into Runtime API calls

## What Is Not a Security Issue?

- **Feature requests** — use GitHub Discussions
- **Terraform errors** — see Terraform documentation
- **Runtime vulnerabilities** — report to the [Runtime security policy](https://github.com/latticeHQ/latticeRuntime/blob/develop/SECURITY.md)

## Disclosure Policy

We follow **coordinated disclosure**:

1. **Report received** — we acknowledge within 48 hours
2. **Investigation** — we validate and assess severity
3. **Fix developed** — we create and test a patch
4. **Coordinated release** — we work with you on timing
5. **Public disclosure** — after fix is deployed

## Contact

- **Security issues:** security@latticeruntime.com
- **General questions:** [GitHub Discussions](https://github.com/latticeHQ/latticeRuntime/discussions)
