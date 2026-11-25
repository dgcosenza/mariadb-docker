# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Image tags track official MariaDB release versions plus immutable `YYYYMMDD` daily build dates.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

---

## [2026-11-25]

### Automated Daily Build
- MariaDB 11.8 rebuilt at `11.8.10` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:f31027e20f117f78d95f6de1a4964c0e47e0a1f7edf25991b634452c677c1044`)
- MariaDB 12.3 rebuilt at `12.3.4` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:d849a0064cd7e52c8d3161ed3da0d82c080f62602af415b922f211579df97981`)

### Security
- Trivy and Grype (SPDX SBOM) gates verified: **0 fixable Critical/High** vulnerabilities across `linux/amd64` and `linux/arm64`; Cosign OIDC signed with SLSA Build L3 provenance.
## [2026-11-24]

### Added
- Initial hardened MariaDB 11.8 LTS (`11.8.10`) and 12.3 LTS (`12.3.4`) images on Debian 13 (`trixie-slim`) using the official GPG-verified MariaDB Debian 13 APT repository.
- Source-rebuilt `gosu 1.20` using Go `1.27.4` (`golang:1.27.4-trixie`) to eliminate fixable Go stdlib vulnerabilities present in prebuilt upstream binaries.
- Full 7-step automated daily CI pipeline: upstream version/release-notes tracking, clean `--no-cache` rebuilds, Trivy + Grype hard gates (0 fixable Critical/High), SPDX-JSON SBOM + provenance, functional smoke tests, automated docs/changelog/Docker Hub sync, and `ci-failure` issue alerting.
- Full drop-in compatibility with upstream `docker-library/mariadb` environment variables, `/docker-entrypoint-initdb.d`, UID/GID `999:999`, and `healthcheck.sh`.

### Security
- Eliminated 26 fixable vulnerabilities (1 Critical, 25 High) found in upstream `mariadb:11.8` / `mariadb:12.3` (`gosu` Go 1.24.6 stdlib).
- Base Debian 13 (`trixie-slim`) packages upgraded at build time; verified 0 fixable Critical/High in Trivy and Grype.
