# MariaDB on Debian 13 (trixie) — Hardened Container Image

[![CI](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml)
[![Docker Hub Pulls](https://img.shields.io/docker/pulls/dgcosenza/mariadb?label=docker%20pulls)](https://hub.docker.com/r/dgcosenza/mariadb)
[![Image Size (11.8)](https://img.shields.io/docker/image-size/dgcosenza/mariadb/11.8?label=size%2011.8)](https://hub.docker.com/r/dgcosenza/mariadb)
[![Image Size (12.3)](https://img.shields.io/docker/image-size/dgcosenza/mariadb/12.3?label=size%2012.3)](https://hub.docker.com/r/dgcosenza/mariadb)
[![License](https://img.shields.io/github/license/dgcosenza/mariadb-docker)](LICENSE)

Hardened, continuously rebuilt **MariaDB 11.8 LTS** and **MariaDB 12.3 LTS** container images on **Debian 13 (`trixie-slim`)**, installing server packages from the official GPG-verified MariaDB Debian 13 APT repository and rebuilding `gosu` from source with the latest patched Go toolchain.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Current Versions

<!-- versions:start -->
_Last verified build: **2026-11-25** (UTC)_

| Track | Upstream Version | Base OS | Step-down Helper | Fixable Critical/High (Trivy / Grype) |
|-------|------------------|---------|------------------|---------------------------------------|
| `11.8` (LTS) | `11.8.10` | Debian `13.8` | `gosu 1.20` (Go `1.27.4`) | 0 / 0 |
| `12.3` (LTS) | `12.3.4` | Debian `13.8` | `gosu 1.20` (Go `1.27.4`) | 0 / 0 |

**Recent upstream updates:**
- Daily base OS (`debian:trixie-slim`) security refresh and CVE-gated verification.
<!-- versions:end -->

## Supported Tags

| Tag Pattern | Track | Notes |
|-------------|-------|-------|
| `11.8`, `latest-11.8` | MariaDB 11.8 LTS | Moving tag for the latest daily 11.8 build |
| `11.8.x`, `11.8.x-YYYYMMDD`, `11.8-sha-<short>` | MariaDB 11.8 LTS | Version and immutable date/commit tags |
| `latest`, `12.3`, `latest-12.3` | MariaDB 12.3 LTS | Moving tag for the latest daily 12.3 build |
| `12.3.x`, `12.3.x-YYYYMMDD`, `12.3-sha-<short>`, `sha-<short>` | MariaDB 12.3 LTS | Version and immutable date/commit tags |

Always pin to an explicit series tag (`11.8` or `12.3`) or an immutable digest (`@sha256:...`) when matching an existing on-disk database series.

## Quick Start

### Docker CLI

```bash
# MariaDB 11.8 LTS
docker run -d --name mariadb \
  --security-opt no-new-privileges:true \
  -e MARIADB_ROOT_PASSWORD=change_me_root \
  -e MARIADB_DATABASE=myapp \
  -e MARIADB_USER=myapp \
  -e MARIADB_PASSWORD=change_me_user \
  -v mariadb_data:/var/lib/mysql \
  -p 127.0.0.1:3306:3306 \
  dgcosenza/mariadb:11.8

# MariaDB 12.3 LTS
docker run -d --name mariadb12 \
  --security-opt no-new-privileges:true \
  -e MARIADB_ROOT_PASSWORD=change_me_root \
  -e MARIADB_DATABASE=myapp \
  -e MARIADB_USER=myapp \
  -e MARIADB_PASSWORD=change_me_user \
  -v mariadb12_data:/var/lib/mysql \
  -p 127.0.0.1:3306:3306 \
  dgcosenza/mariadb:12.3
```

### Docker Compose

```yaml
services:
  mariadb:
    image: dgcosenza/mariadb:11.8
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_DATABASE=myapp
      - MARIADB_USER=myapp
      - MARIADB_PASSWORD=${MARIADB_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  mariadb_data:
```

See [docker-compose.example.yml](docker-compose.example.yml) for a complete multi-instance example with internal networks and resource limits.

## Configuration

### Environment Variables

Full drop-in compatibility with the official `docker-library/mariadb` entrypoint:

| Variable | Description | Required |
|----------|-------------|----------|
| `MARIADB_ROOT_PASSWORD` | Root password (or `MARIADB_ROOT_PASSWORD_FILE` for Docker secrets) | Yes¹ |
| `MARIADB_ROOT_PASSWORD_HASH` | Pre-hashed root password | No |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | Allow an empty root password (development only) | No |
| `MARIADB_RANDOM_ROOT_PASSWORD` | Generate a random root password printed to logs | No |
| `MARIADB_DATABASE` | Create a database on first initialization | No |
| `MARIADB_USER` | Create an application user on first initialization | No |
| `MARIADB_PASSWORD` | Password for `MARIADB_USER` (or `MARIADB_PASSWORD_FILE`) | No² |
| `MARIADB_PASSWORD_HASH` | Pre-hashed password for `MARIADB_USER` | No |
| `MARIADB_AUTO_UPGRADE` | Run `mariadb-upgrade` automatically when needed | No |
| `MARIADB_REPLICATION_USER` | Replication user name | No |
| `MARIADB_REPLICATION_PASSWORD` | Replication user password | No |
| `MARIADB_MASTER_HOST` | Primary host for replica initialization | No |
| `ALLOW_EMPTY_PASSWORD` | Compatibility alias | No |

¹ Required on first initialization unless `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` or `MARIADB_RANDOM_ROOT_PASSWORD` is set.  
² Required when `MARIADB_USER` is set.

Legacy `MYSQL_*` aliases (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `*_FILE` variants) are fully supported.

### Volumes

| Path | Purpose |
|------|---------|
| `/var/lib/mysql` | Persistent database data directory (owned by `999:999`) |
| `/docker-entrypoint-initdb.d` | First-start initialization scripts (`*.sh`, `*.sql`, `*.sql.gz`, `*.sql.xz`, `*.sql.zst`) |
| `/etc/mysql/conf.d` | Custom `.cnf` server overrides |

### Ports

- `3306/tcp` — MariaDB client protocol (bind to `127.0.0.1` or an internal Docker network rather than exposing publicly).

### User, UID, and GID

- Runs as non-root `mysql:mysql` (**UID 999 / GID 999**) by default, matching the upstream `docker-library/mariadb` UID/GID.
- If a host bind mount is pre-owned by `root` and cannot be pre-chowned, starting with `--user 0` causes `docker-entrypoint.sh` to adjust `/var/lib/mysql` ownership and immediately step down to `mysql` via the rebuilt `gosu` binary.

### Healthcheck

```bash
healthcheck.sh --connect --innodb_initialized
```

Verifies both client connectivity and InnoDB initialization without triggering unauthenticated "Access denied" warnings in the server log.

## Upgrade and Migration from Upstream `mariadb`

This image is a drop-in replacement for the official `mariadb:11.8` and `mariadb:12.3` images:

1. **Back up first:** Take a verified logical dump (`mariadb-dump --all-databases --single-transaction`) or physical backup (`mariadb-backup`) before changing images.
2. **Match the major series:** Migrate `mariadb:11.8` only to `dgcosenza/mariadb:11.8` and `mariadb:12.3` only to `dgcosenza/mariadb:12.3`. Never downgrade a data directory across major series.
3. **Verify directory ownership:** Existing data directories created by upstream `mariadb` are already owned by UID/GID `999:999`, so non-root startup works out of the box.
4. **Keep rollback ready:** Tag the previous image locally before switching so you can revert immediately if needed.
5. **Switch image reference:** Replace `image: mariadb:11.8` (or `12.3`) with `image: dgcosenza/mariadb:11.8` (or `12.3` / pinned `@sha256:...`) and recreate only the database service (`docker compose up -d <service>`).

## Security

### Scanning Policy

- **Trivy** (OS + language packages): SARIF uploaded to GitHub Code Scanning, full table and JSON reports retained for 90 days, and a **blocking hard gate** that fails on any fixable `CRITICAL` or `HIGH` vulnerability.
- **Grype**: **blocking hard gate** (`--only-fixed`, severity cutoff `high`) with table report retained for 90 days.
- **SBOM and Provenance**: SPDX-JSON SBOM generated via Syft plus build provenance JSON uploaded as 90-day artifacts on every build.
- **Unfixable vulnerabilities**: None currently affecting Critical/High; any future upstream-unfixed findings are tracked in the daily Trivy/Grype artifacts and resolved automatically once a vendor fix ships.

### Reporting Vulnerabilities

See [SECURITY.md](SECURITY.md) for private disclosure via GitHub's **Security** tab.

## Build Locally

```bash
# Build MariaDB 11.8 LTS
docker buildx build --platform linux/amd64 --load \
  --build-arg MARIADB_MAJOR=11.8 \
  --build-arg MARIADB_VERSION=11.8.10 \
  -t dgcosenza/mariadb:11.8-local .

# Build MariaDB 12.3 LTS
docker buildx build --platform linux/amd64 --load \
  --build-arg MARIADB_MAJOR=12.3 \
  --build-arg MARIADB_VERSION=12.3.4 \
  -t dgcosenza/mariadb:12.3-local .
```

## Update Policy

Every day at **04:32 UTC** (and on every push to `main`, pull request, or manual dispatch), `.github/workflows/daily.yml` runs a fully automated 7-step pipeline after passing `.github/scripts/public-check.sh`:

1. **Upstream check:** Queries the authenticated GitHub API (`MariaDB/server`, `tianon/gosu`), `archive.mariadb.org`, and `go.dev` to resolve the newest official patch release per series and the latest patched Go toolchain, diffs against `versions.json`, and saves `upstream-changes-<series>.md` as a 90-day artifact.
2. **Clean rebuild:** Rebuilds both tracks on `debian:trixie-slim` with `--no-cache` on scheduled runs, running `apt-get upgrade` and compiling `gosu` from source with the resolved Go release, then produces an SPDX-JSON SBOM and provenance record.
3. **Vulnerability fix & hard gates:** Runs Trivy (table, JSON, SARIF upload, and blocking 0 fixable `CRITICAL`/`HIGH` gate) and Grype (blocking 0 fixable `CRITICAL`/`HIGH` gate), retaining all reports for 90 days and diffing CVEs resolved since the prior build.
4. **Functional smoke test:** Runs `tests/smoke.sh` to verify healthy startup, UID 999 non-root execution, version accuracy, `/docker-entrypoint-initdb.d` execution, SQL CRUD, `mariadb-backup`, and negative healthcheck failure.
5. **Registry publish:** On non-PR runs when Docker Hub credentials are configured, pushes versioned, immutable date-stamped (`<version>-<YYYYMMDD>`), commit (`sha-<short>`), and moving series tags, recording the published digest.
6. **Automated documentation sync:** Commits updated `versions.json`, the `<!-- versions:start -->` block in `README.md`, and dated `CHANGELOG.md` entries via `github-actions[bot]` (`[skip ci]`, validated by `public-check.sh`) whenever metadata changes, then syncs the README and short description to Docker Hub.
7. **Failure alerting:** Automatically opens or updates a single GitHub issue labeled `ci-failure` if any step fails on `main` or a scheduled run, and auto-closes it on the next green build.

## Design Decisions

- **Debian 13 (`trixie-slim`) base:** Follows the standard minimal Debian stable base with `apt-get upgrade` on every build rather than Ubuntu, using MariaDB's official Debian 13 (`trixie`) APT repository with GPG fingerprint verification (`177F4010FE56CA3336300305F1656F24C74CD1D8`).
- **Source-rebuilt `gosu`:** Official upstream MariaDB images ship prebuilt `gosu` binaries compiled with older Go toolchains that accumulate dozens of fixable Go stdlib CVEs. Compiling `gosu` from source in a multi-stage `golang:<latest>-trixie` builder removes those CVEs while keeping `--user 0` step-down support intact.
- **Direct `mariadbd` PID 1 (`exec`):** The entrypoint replaces itself via `exec mariadbd`, matching upstream `docker-library/mariadb` so `SIGTERM` triggers a clean InnoDB shutdown without wrapper overhead.
- **Non-root default (`USER mysql:mysql`):** Matches UID/GID 999 for zero-friction compatibility with existing MariaDB volumes while preventing unnecessary root execution.

## License

- Repository build files, scripts, and documentation: **MIT License** — see [LICENSE](LICENSE).
- MariaDB Server and upstream entrypoint/healthcheck scripts: **GPL-2.0-only** — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Credits

- [MariaDB Foundation](https://mariadb.org/) and [MariaDB/mariadb-docker](https://github.com/MariaDB/mariadb-docker)
- [tianon/gosu](https://github.com/tianon/gosu)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
