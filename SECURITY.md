# Security Policy

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Supported Versions

Only the latest daily build for each supported MariaDB LTS series receives security updates.

| Series | Moving Tags | Supported |
|--------|-------------|-----------|
| 11.8 LTS | `11.8`, `latest-11.8` | Yes |
| 12.3 LTS | `latest`, `12.3`, `latest-12.3` | Yes |

Immutable date-stamped tags (such as `11.8.10-20261124`) are frozen for reproducibility and are not overwritten.

## Vulnerability Scanning & Gates

- **Trivy** (OS + language packages): SARIF uploaded to GitHub Code Scanning; table and JSON reports retained for 90 days; **blocking hard gate** on any fixable `CRITICAL` or `HIGH` finding.
- **Grype**: **blocking hard gate** (`only-fixed: true`, severity cutoff `high`); table report retained for 90 days.
- **SBOM & Provenance**: SPDX-JSON SBOM via Syft plus build provenance JSON retained for 90 days.

## Reporting a Vulnerability

**Do not open a public issue** for security vulnerabilities.

Report privately through GitHub's private vulnerability reporting: open the repository's **Security** tab and select **Report a vulnerability**.

Please include a description of the vulnerability, affected tag or digest, reproduction steps, and any suggested remediation. We aim to acknowledge reports within 48 hours and remediate fixable vulnerabilities in the next daily build or an immediate manual dispatch.

## Hardening Highlights

- Minimal `debian:trixie-slim` base with `apt-get upgrade` on every build
- Official MariaDB Debian 13 APT repository verified against key fingerprint `177F4010FE56CA3336300305F1656F24C74CD1D8`
- `gosu` compiled from source using the latest patched Go toolchain
- Non-root default execution (`mysql:mysql`, UID/GID `999:999`)
- Compatible with `security_opt: [no-new-privileges:true]`
