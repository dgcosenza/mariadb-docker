# MariaDB on Debian 13 (trixie) — Hardened Container Image

[![Daily MariaDB image](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/mariadb-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/mariadb-docker/blob/main/LICENSE)
[![Upstream License: GPL-2.0-only](https://img.shields.io/badge/upstream-GPL--2.0--only-green.svg)](https://github.com/MariaDB/server/blob/main/COPYING)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/mariadb-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/mariadb-docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/mariadb)](https://hub.docker.com/r/dgcosenza/mariadb)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/mariadb/12.3)](https://hub.docker.com/r/dgcosenza/mariadb)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/mariadb-docker?label=version)](https://github.com/dgcosenza/mariadb-docker/releases)

Hardened, multi-arch, rootless **MariaDB 11.8 LTS** and **MariaDB 12.3 LTS** container images on **Debian 13 (`trixie-slim`)**, installing server packages from the official GPG-verified MariaDB Debian 13 APT repository and rebuilding `gosu` from source with the latest patched Go toolchain, maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/mariadb`](https://hub.docker.com/r/dgcosenza/mariadb)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/mariadb`](https://github.com/dgcosenza/mariadb-docker/pkgs/container/mariadb) (identical signed multi-arch digests)
- **Source Repository:** [`dgcosenza/mariadb-docker`](https://github.com/dgcosenza/mariadb-docker)
- **Upstream Application:** [`MariaDB/server`](https://github.com/MariaDB/server) (`GPL-2.0-only`)

---

## Current Versions

<!-- versions:start -->
_Last verified build: **2026-11-25** (UTC) — multi-arch (`linux/amd64`, `linux/arm64`), Cosign OIDC signed, SPDX & CycloneDX SBOM attested, SLSA Build L3 provenance._

| Track | Upstream Version | Base OS | Step-down Helper | Uncompressed Size | Fixable Critical/High (Trivy + Grype SBOM) |
| --- | --- | --- | --- | --- | --- |
| `11.8` (LTS) | `11.8.10` | Debian `13.8` | `gosu 1.20` (Go `1.27.4`) | `amd64: 128.2 MB, arm64: 453.2 MB` | **0** (18 unfixed) |
| `12.3` (LTS) | `12.3.4` | Debian `13.8` | `gosu 1.20` (Go `1.27.4`) | `amd64: 129.7 MB, arm64: 458.0 MB` | **0** (18 unfixed) |

**Published multi-arch digests (identical on Docker Hub & GHCR):**
- **MariaDB `11.8` (`11.8.10`):** `dgcosenza/mariadb@sha256:f31027e20f117f78d95f6de1a4964c0e47e0a1f7edf25991b634452c677c1044` / `ghcr.io/dgcosenza/mariadb@sha256:f31027e20f117f78d95f6de1a4964c0e47e0a1f7edf25991b634452c677c1044`
- **MariaDB `12.3` (`12.3.4`):** `dgcosenza/mariadb@sha256:d849a0064cd7e52c8d3161ed3da0d82c080f62602af415b922f211579df97981` / `ghcr.io/dgcosenza/mariadb@sha256:d849a0064cd7e52c8d3161ed3da0d82c080f62602af415b922f211579df97981`
<!-- versions:end -->

---

## Supported Tags & Tag Policy

Identical multi-arch OCI digests are published to **Docker Hub** (`dgcosenza/mariadb`) and **GHCR** (`ghcr.io/dgcosenza/mariadb`), accompanied by an automated signed [GitHub Release](https://github.com/dgcosenza/mariadb-docker/releases):

| Tag Pattern | Track | Policy | Notes |
| --- | --- | --- | --- |
| `11.8.x-<YYYYMMDD>`, `11.8-sha-<short>` | MariaDB 11.8 LTS | **Immutable** | Date- and commit-pinned daily 11.8 LTS builds |
| `11.8`, `latest-11.8`, `11.8.x` | MariaDB 11.8 LTS | Moving | Latest verified daily 11.8 LTS build |
| `12.3.x-<YYYYMMDD>`, `12.3-sha-<short>`, `sha-<short>` | MariaDB 12.3 LTS | **Immutable** | Date- and commit-pinned daily 12.3 LTS builds |
| `latest`, `12.3`, `latest-12.3`, `12.3.x` | MariaDB 12.3 LTS | Moving | Latest verified daily 12.3 LTS build |

**Production pinning:** Always pin an explicit series tag and immutable digest (`@sha256:...`) matching your on-disk database series:

```yaml
image: dgcosenza/mariadb:11.8@sha256:<digest>
# or via GitHub Container Registry (identical digest):
image: ghcr.io/dgcosenza/mariadb:12.3@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Both `11.8` and `12.3` built, smoke-tested (`--cap-drop ALL`, UID `999`), Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Both `11.8` and `12.3` built, smoke-tested (`--cap-drop ALL`, UID `999`), Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

---

## Quick Start

### Docker CLI (hardened, rootless)

```bash
docker run -d --name mariadb \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --tmpfs /run/mysqld:uid=999,gid=999,mode=1777,size=16m \
  --tmpfs /tmp:mode=1777,size=128m \
  -e MARIADB_ROOT_PASSWORD=change_me_root \
  -e MARIADB_DATABASE=myapp \
  -e MARIADB_USER=myapp \
  -e MARIADB_PASSWORD=change_me_user \
  -v mariadb_data:/var/lib/mysql \
  -p 127.0.0.1:3306:3306 \
  dgcosenza/mariadb:11.8
```

### Hardened Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/mariadb-docker/blob/main/docker-compose.example.yml):

```yaml
services:
  mariadb:
    image: dgcosenza/mariadb:11.8
    restart: unless-stopped
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /run/mysqld:uid=999,gid=999,mode=1777,size=16m
      - /tmp:mode=1777,size=128m
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

---

## Configuration

### Environment Variables

Full drop-in compatibility with the official `docker-library/mariadb` entrypoint (including legacy `MYSQL_*` and `*_FILE` aliases):

| Variable | Description | Required |
| --- | --- | --- |
| `MARIADB_ROOT_PASSWORD` | Root password (or `MARIADB_ROOT_PASSWORD_FILE` for Docker secrets) | Yes¹ |
| `MARIADB_ROOT_PASSWORD_HASH` | Pre-hashed root password | No |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | Allow an empty root password (development only) | No |
| `MARIADB_RANDOM_ROOT_PASSWORD` | Generate a random root password printed to logs | No |
| `MARIADB_DATABASE` | Create a database on first initialization | No |
| `MARIADB_USER` | Create an application user on first initialization | No |
| `MARIADB_PASSWORD` | Password for `MARIADB_USER` (or `MARIADB_PASSWORD_FILE`) | No² |
| `MARIADB_PASSWORD_HASH` | Pre-hashed password for `MARIADB_USER` | No |
| `MARIADB_AUTO_UPGRADE` | Run `mariadb-upgrade` automatically when needed | No |
| `MARIADB_REPLICATION_USER` / `MARIADB_REPLICATION_PASSWORD` / `MARIADB_MASTER_HOST` | Replica setup | No |

¹ Required on first initialization unless `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` or `MARIADB_RANDOM_ROOT_PASSWORD` is set.  
² Required when `MARIADB_USER` is set.

### Volumes, Ports, and UID/GID

| Path / Port | Mode / Owner | Purpose |
| --- | --- | --- |
| `/var/lib/mysql` | `999:999` (`mysql`) | Persistent database data directory |
| `/docker-entrypoint-initdb.d` | Read-only | First-start initialization scripts (`*.sh`, `*.sql`, `*.sql.{gz,xz,zst}`) |
| `/etc/mysql/conf.d` | Read-only | Custom `.cnf` server overrides |
| `3306/tcp` | Internal | MariaDB client protocol |

Runs as non-root **`mysql:mysql` (UID/GID `999:999`)** by default, compatible with `read_only: true`, `cap_drop: [ALL]`, and `no-new-privileges:true`.

---

## Healthcheck

```bash
healthcheck.sh --connect --innodb_initialized
```

---

## Upgrade and Migration from Upstream `mariadb`

1. **Back up first:** Take a verified logical dump (`mariadb-dump --all-databases --single-transaction`) or physical backup (`mariadb-backup`) before changing images.
2. **Match the major series:** Migrate `mariadb:11.8` only to `dgcosenza/mariadb:11.8` and `mariadb:12.3` only to `dgcosenza/mariadb:12.3`. Never downgrade across major series.
3. **Keep rollback ready:** Tag the previous image locally before switching.
4. **Switch image reference:** Pin `dgcosenza/mariadb:11.8@sha256:<digest>` (or `12.3`) and run `docker compose up -d <service>`.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests for both `11.8` and `12.3`) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/mariadb-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/mariadb:12.3

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/mariadb-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/mariadb:11.8
```

### Verify SPDX / CycloneDX SBOM attestations

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/mariadb-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/mariadb@sha256:<arch-digest>
```

### Verify SLSA Build Provenance

```bash
gh attestation verify oci://ghcr.io/dgcosenza/mariadb:12.3 --owner dgcosenza
```

---

## Security

- **Preflight gates:** Every push and PR runs **Hadolint** (blocking on warning+), **Gitleaks** secret scanning across git history, and **public-content/attribution** checks.
- **Vulnerability scan policy:** Every build generates **SPDX** and **CycloneDX** SBOMs with **Syft** per series and architecture, scans with **Trivy** (table, JSON, SARIF upload, blocking `--ignore-unfixed` gate) and **Grype** scanning the SPDX SBOM (`--only-fixed --fail-on high`), and enforces a **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted user bytes).
- **Current status:** **0 fixable Critical/High** vulnerabilities across Debian 13 OS packages, MariaDB 11.8/12.3 LTS, and source-built `gosu`.
- **Dependency automation:** Renovate (`renovate.json`) pins base image digests and GitHub Action commit SHAs; Dependabot security alerts and OpenSSF Scorecard monitoring are enabled.
- See [`SECURITY.md`](https://github.com/dgcosenza/mariadb-docker/blob/main/SECURITY.md) for responsible disclosure.

---

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

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/mariadb-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **04:32 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`:

1. **Preflight & upstream check:** Runs public-content checks, **Hadolint**, and **Gitleaks**; queries the authenticated GitHub API (`MariaDB/server`, `tianon/gosu`), `archive.mariadb.org`, `go.dev`, and Docker Hub for digest-pinned base images, emitting `upstream-changes-11.8.md` and `upstream-changes-12.3.md`.
2. **Multi-arch no-cache rebuild:** Rebuilds both `11.8` and `12.3` natively on `linux/amd64` and `linux/arm64` runners with `--no-cache` on schedule, running `apt-get upgrade` and compiling `gosu` from source with the latest patched Go release.
3. **Smoke, Dive & vulnerability gates:** Runs [`tests/smoke.sh`](https://github.com/dgcosenza/mariadb-docker/blob/main/tests/smoke.sh) natively on all 4 matrix targets, enforces the **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted), generates **Syft** SPDX + CycloneDX SBOMs per arch, and gates publication on **0 fixable Critical/High** in both **Trivy** and **Grype** (scanning the SPDX SBOM).
4. **Dual-registry publish & supply-chain signing:** Assembles multi-arch OCI manifest indexes for both `11.8` and `12.3` on **GHCR** (`ghcr.io/dgcosenza/mariadb`) and mirrors identical digests to **Docker Hub** (`dgcosenza/mariadb`); signs every digest and attaches SPDX/CycloneDX SBOM attestations via **Cosign** keyless OIDC; emits **SLSA Build L3** provenance for both series; and publishes a signed **GitHub Release** with checksums and SBOMs.
5. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` (`[skip ci]`, validated by `public-check.sh`), then syncs the Docker Hub overview and short description.
6. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and auto-closes it on the next green run.

---

## Design Decisions

- **Debian 13 (`trixie-slim`) base:** Uses MariaDB's official Debian 13 (`trixie`) APT repository (`archive.mariadb.org`, GPG fingerprint `177F4010FE56CA3336300305F1656F24C74CD1D8`) for both `amd64` and `arm64`.
- **Source-rebuilt `gosu`:** Eliminates stale Go stdlib CVEs present in prebuilt upstream `gosu` binaries while keeping `--user 0` step-down support intact.
- **Direct `mariadbd` PID 1 (`exec`):** Ensures `SIGTERM` triggers a clean InnoDB shutdown without wrapper overhead.
- **Hadolint `DL3008` ignore:** Daily `--no-cache` security rebuilds intentionally pull the newest Debian 13 security updates via `apt-get`.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, CI workflows, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/mariadb-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — MariaDB Server & upstream entrypoint/healthcheck scripts (`upstream: GPL-2.0-only`):** Copyright MariaDB Foundation and contributors — licensed under the [GNU General Public License v2.0](https://github.com/MariaDB/server/blob/main/COPYING).

Full third-party notices are maintained in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/mariadb-docker/blob/main/THIRD-PARTY-NOTICES.md). Release history is maintained in [`CHANGELOG.md`](https://github.com/dgcosenza/mariadb-docker/blob/main/CHANGELOG.md).

## Credits

- [MariaDB Foundation](https://mariadb.org/) and [MariaDB/mariadb-docker](https://github.com/MariaDB/mariadb-docker)
- [tianon/gosu](https://github.com/tianon/gosu)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
