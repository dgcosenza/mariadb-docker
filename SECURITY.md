# Security Policy

## Supported Versions

Only the latest daily build for each supported MariaDB major series receives security updates.

| Series | Tag | Supported |
|--------|-----|-----------|
| 11.8 (LTS) | `latest-11.8`, `11.8` | ✅ Yes |
| 12.3 (LTS) | `latest-12.3`, `12.3` | ✅ Yes |

Older immutable tags (e.g., `11.8.10-20261124`) are **not updated** — they are frozen for reproducibility. Always use the moving tags (`latest-<major>` or `<major>`) for production deployments to receive daily security patches.

## Vulnerability Scanning & Remediation

### Daily Automated Scans
- **Trivy** (OS packages + language-specific): Hard gate — build fails on any fixable CRITICAL or HIGH
- **Grype** (OS packages + language-specific): Informational artifact
- **Syft SBOM** (SPDX-JSON): Generated and stored as artifact (30-day retention)

### Remediation Process
1. Daily CI run detects fixable vulnerabilities
2. If fixable CRITICAL/HIGH found:
   - Base OS: `apt-get upgrade` in next daily build (automatic)
   - gosu: Rebuilt from source with patched Go version (automatic via CI)
   - MariaDB: New patch version from official apt repo (automatic via version resolution)
3. Build only publishes if **zero fixable CRITICAL/HIGH** remain

### Current Baseline (2026-11-24)
| Component | Fixable Critical | Fixable High | Status |
|-----------|------------------|--------------|--------|
| Debian 13 base | 0 | 0 | ✅ Clean |
| gosu (rebuilt, Go 1.25.7) | 0 | 0 | ✅ Clean |
| MariaDB 11.8.10 / 12.3.4 | 0 | 0 | ✅ Clean |

*Upstream MariaDB Docker images (Ubuntu noble base, gosu 1.20) had 26 fixable findings in gosu stdlib.*

## Reporting a Vulnerability

**Do not open a public issue** for security vulnerabilities.

Report privately through GitHub's private vulnerability reporting: open the repository's **Security** tab and select **Report a vulnerability**.

Include:
- Description of the vulnerability
- Steps to reproduce
- Affected tags/versions
- Suggested fix (if known)

We aim to acknowledge within 48 hours and publish a fix in the next daily build (or sooner via manual workflow dispatch for critical issues).

## Hardening Measures

### Image Build
- Debian 13 (trixie-slim) — minimal base
- Full `apt-get upgrade` at build time
- `--no-install-recommends` for all apt installs
- Apt cache and lists cleaned
- gosu rebuilt from source with Go ≥1.25.7 (fixes stdlib CVEs)
- MariaDB from official signed apt repository (GPG verified)
- Non-root user (mysql, UID 999) created at build time
- `USER mysql:mysql` in final image

### Runtime (recommended)
```yaml
security_opt:
  - no-new-privileges:true
read_only: true  # with writable volumes for /var/lib/mysql, /run/mysqld, /docker-entrypoint-initdb.d, /etc/mysql/conf.d
tmpfs:
  - /run/mysqld
  - /tmp
cap_drop:
  - ALL
```

### Network
- Expose only port 3306 to trusted networks
- Use Docker internal networks (no `0.0.0.0:3306` in production)
- Consider TLS for client connections (MariaDB supports `--ssl`)

### Secrets
- Use Docker secrets (`MARIADB_ROOT_PASSWORD_FILE`, `MARIADB_PASSWORD_FILE`)
- Never bake passwords into images or compose files
- Rotate passwords periodically

## Supply Chain

- **Base image:** `debian:trixie-slim` (official Docker Hub library image)
- **MariaDB packages:** `archive.mariadb.org` (official, GPG-signed repository)
- **gosu source:** `github.com/tianon/gosu` (pinned tag, verified via Go module checksums)
- **Go toolchain:** `golang:<version>-trixie-slim` (official Docker Hub library image)
- **CI:** GitHub Actions (pinned action SHAs, least-privilege permissions)
- **SBOM:** Generated via Syft at build time
- **Provenance:** Buildx attestation (when publishing)

## License Compliance

- MariaDB Server: GPL-2.0-only (redistribution permitted)
- gosu: MIT
- Debian packages: DFSG-compatible
- This repository: MIT

See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for full details.