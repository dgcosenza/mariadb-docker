# MariaDB on Debian 13 (trixie) — Hardened Container Image

[![CI](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml)
[![Docker Hub Pulls](https://img.shields.io/docker/pulls/dgcosenza/mariadb?label=docker%20pulls)](https://hub.docker.com/r/dgcosenza/mariadb)
[![Image Size](https://img.shields.io/docker/image-size/dgcosenza/mariadb/latest-11.8?label=image%20size%20(11.8))](https://hub.docker.com/r/dgcosenza/mariadb)
[![Image Size](https://img.shields.io/docker/image-size/dgcosenza/mariadb/latest-12.3?label=image%20size%20(12.3))](https://hub.docker.com/r/dgcosenza/mariadb)
[![License](https://img.shields.io/github/license/dgcosenza/mariadb-docker)](LICENSE)

A hardened, up-to-date MariaDB container image built on **Debian 13 (trixie-slim)**, using the **official MariaDB apt repository** for the database server packages. Maintained by **Daniel G. Cosenza from FNX Labs**.

## Supported Tags

| Tag | MariaDB Series | Base | Status |
|-----|----------------|------|--------|
| `latest-11.8`, `11.8`, `11.8.<version>-<YYYYMMDD>`, `11.8.<version>-<short-sha>` | 11.8 (LTS) | Debian 13 (trixie) | ✅ Active |
| `latest-12.3`, `12.3`, `12.3.<version>-<YYYYMMDD>`, `12.3.<version>-<short-sha>` | 12.3 (LTS) | Debian 13 (trixie) | ✅ Active |

**Tag scheme:**
- `latest-<major>` — moving tag, always the newest build for that major series
- `<major>` — alias for `latest-<major>`
- `<major>.<version>` — immutable tag for a specific MariaDB version (e.g., `11.8.10`)
- `<major>.<version>-<YYYYMMDD>` — immutable date-stamped tag (e.g., `11.8.10-20261124`)
- `<major>.<version>-<short-sha>` — immutable git commit tag (e.g., `11.8.10-a1b2c3d`)

## Quick Start

### Docker CLI

```bash
# MariaDB 11.8 (LTS)
docker run -d --name mariadb \
  -e MARIADB_ROOT_PASSWORD=your_root_password \
  -e MARIADB_DATABASE=myapp \
  -e MARIADB_USER=myapp \
  -e MARIADB_PASSWORD=your_user_password \
  -v mariadb_data:/var/lib/mysql \
  -p 3306:3306 \
  dgcosenza/mariadb:11.8

# MariaDB 12.3 (LTS)
docker run -d --name mariadb \
  -e MARIADB_ROOT_PASSWORD=your_root_password \
  -e MARIADB_DATABASE=myapp \
  -e MARIADB_USER=myapp \
  -e MARIADB_PASSWORD=your_user_password \
  -v mariadb_data:/var/lib/mysql \
  -p 3306:3306 \
  dgcosenza/mariadb:12.3
```

### Docker Compose

```yaml
services:
  mariadb:
    image: dgcosenza/mariadb:11.8
    security_opt:
      - no-new-privileges:true
    environment:
      - MARIADB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MARIADB_DATABASE=myapp
      - MARIADB_USER=myapp
      - MARIADB_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./data:/var/lib/mysql
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped
```

See [docker-compose.example.yml](docker-compose.example.yml) for a complete example with resource limits and multiple databases.

## Configuration

### Environment Variables

All standard MariaDB docker-entrypoint environment variables are supported (full compatibility with `docker-library/mariadb`):

| Variable | Description | Required |
|----------|-------------|----------|
| `MARIADB_ROOT_PASSWORD` | Root password (or use `*_FILE` for Docker secrets) | Yes¹ |
| `MARIADB_ROOT_PASSWORD_HASH` | Root password hash (alternative to password) | No |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | Allow empty root password (dev only) | No |
| `MARIADB_RANDOM_ROOT_PASSWORD` | Generate random root password (printed to logs) | No |
| `MARIADB_DATABASE` | Create a database on first start | No |
| `MARIADB_USER` | Create a user with access to `MARIADB_DATABASE` | No |
| `MARIADB_PASSWORD` | Password for `MARIADB_USER` | No² |
| `MARIADB_PASSWORD_HASH` | Password hash for `MARIADB_USER` | No |
| `MARIADB_ROOT_PASSWORD_FILE` | Path to file containing root password | No |
| `MARIADB_PASSWORD_FILE` | Path to file containing user password | No |
| `MARIADB_REPLICATION_USER` | Replication user name | No |
| `MARIADB_REPLICATION_PASSWORD` | Replication user password | No |
| `MARIADB_MASTER_HOST` | Master host for replica setup | No |
| `ALLOW_EMPTY_PASSWORD` | Legacy alias for `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | No |

¹ Required unless `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` or `MARIADB_RANDOM_ROOT_PASSWORD` is set.  
² Required if `MARIADB_USER` is set.

**MySQL-compatible aliases** (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`) are also supported and kept in sync.

### Volumes

| Path | Description |
|------|-------------|
| `/var/lib/mysql` | Database data directory (persist this!) |
| `/docker-entrypoint-initdb.d` | Initialization scripts (`*.sh`, `*.sql`, `*.sql.gz`, `*.sql.xz`, `*.sql.zst`) |
| `/etc/mysql/conf.d` | Additional `.cnf` configuration files |

### Ports

- `3306/tcp` — MariaDB protocol

### Healthcheck

Built-in healthcheck script (from upstream MariaDB Docker) runs:
```bash
healthcheck.sh --connect --innodb_initialized
```
This verifies TCP connectivity and that InnoDB crash recovery has completed.

### User/UID/GID

- **User:** `mysql` (UID 999, GID 999) — matches upstream `docker-library/mariadb` convention
- Runs as non-root by default (`USER mysql:mysql` in Dockerfile)

## Design Decisions

### Base Image: Debian 13 (trixie-slim)
- Minimal attack surface, official Debian stable release
- Full `apt-get upgrade` at build time (security patches applied daily via CI)
- `--no-install-recommends` and cleaned apt lists

### MariaDB from Official Apt Repository
- Installs `mariadb-server` (11.8) or `mariadb-server-galera` (12.3) directly from `archive.mariadb.org`
- Repository pinning (priority 999) ensures MariaDB packages are preferred over Debian's
- Version resolved daily in CI from GitHub releases API (authenticated)

### gosu Rebuilt from Source
- Upstream gosu 1.20 is built with Go 1.24.6, which has fixable CVEs in the stdlib
- This image **rebuilds gosu from source** using Go 1.25.7+ (first version with all fixes)
- Verified: `gosu --version` and `gosu nobody true` at build time

### Non-Root by Default
- `mysql` user (UID 999) created at build time
- All runtime directories owned by `mysql:mysql`
- Container runs `USER mysql:mysql`

### OCI Labels
Full OCI image-spec labels including version, revision, created date, source, licenses, and vendor.

### Healthcheck
Uses upstream `healthcheck.sh` with `--connect --innodb_initialized` — same as official image.

### Initialization Compatibility
Full compatibility with `docker-library/mariadb` entrypoint:
- `MARIADB_*` and `MYSQL_*` environment variables
- `/docker-entrypoint-initdb.d` scripts (`.sh`, `.sql`, `.sql.gz`, `.sql.xz`, `.sql.zst`)
- File-based secrets (`*_FILE` suffix)
- Replication setup variables

## Security

### Vulnerability Scanning Policy
- **Daily Trivy scan** (OS + language packages) in CI — **hard gate: fails on any fixable CRITICAL or HIGH**
- **Daily Grype scan** — informational artifact
- **SBOM** (Syft, SPDX-JSON) generated and uploaded as artifact
- **Provenance** via buildx `sbom: true`

### Current Scan Status
| Series | Trivy (fixable Critical/High) | Grype (fixable Critical/High) |
|--------|-------------------------------|-------------------------------|
| 11.8   | 0                             | 0                             |
| 12.3   | 0                             | 0                             |

*Scans run daily; see [GitHub Actions](https://github.com/dgcosenza/mariadb-docker/actions) for latest results.*

### Hardening Measures
- `no-new-privileges:true` security opt (enforced in compose example)
- Non-root execution (UID 999)
- Minimal base image (trixie-slim)
- Apt packages cleaned after install
- gosu rebuilt with patched Go toolchain
- Read-only root filesystem compatible (writable dirs: `/var/lib/mysql`, `/run/mysqld`, `/docker-entrypoint-initdb.d`, `/etc/mysql/conf.d`, `/tmp`)

### Reporting Security Issues
See [SECURITY.md](SECURITY.md) for responsible disclosure process.

## Build Locally

```bash
# Build MariaDB 11.8
docker buildx build --platform linux/amd64 --load \
  --build-arg MARIADB_MAJOR=11.8 \
  --build-arg MARIADB_VERSION=11.8.10 \
  -t mariadb-local:11.8 .

# Build MariaDB 12.3
docker buildx build --platform linux/amd64 --load \
  --build-arg MARIADB_MAJOR=12.3 \
  --build-arg MARIADB_VERSION=12.3.4 \
  -t mariadb-local:12.3 .
```

Overridable build args:
- `MARIADB_MAJOR` (11.8 or 12.3)
- `MARIADB_VERSION` (full version, e.g., 11.8.10)
- `GOSU_VERSION` (default: 1.20)
- `GO_VERSION` (default: 1.25.7)
- `GPG_KEYS` (MariaDB signing key)
- `DEBIAN_VERSION` (default: trixie-slim)

## Update Policy

- **Daily scheduled builds** (04:32 UTC) via GitHub Actions
- Each run:
  1. Resolves latest MariaDB patch version for 11.8 and 12.3 series from GitHub API
  2. Rebuilds gosu from source with current Go 1.25.x
  3. Runs `apt-get upgrade` on Debian base
  4. Builds, smoke-tests, scans (Trivy + Grype), generates SBOM
  5. Publishes to Docker Hub if secrets configured
- **Manual triggers**: `workflow_dispatch` with version overrides
- **Dependabot**: Daily checks for GitHub Actions and Docker base image updates

## License

- **This repository**: MIT License (see [LICENSE](LICENSE))
- **MariaDB Server**: GPL-2.0-only (see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md))
- **gosu**: MIT License (bundled, rebuilt from source)
- **Debian base**: Various (Debian main repository)

Redistribution of MariaDB binaries is permitted under GPL-2.0-only. This image builds from the official MariaDB apt repository.

## Credits

- **Upstream MariaDB Docker**: https://github.com/MariaDB/mariadb-docker (entrypoint, healthcheck, Dockerfile structure)
- **MariaDB Server**: https://mariadb.org/
- **gosu**: https://github.com/tianon/gosu
- **Debian**: https://www.debian.org/

Maintained by **Daniel G. Cosenza from FNX Labs**.