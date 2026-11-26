# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Image tags track official MariaDB release versions plus immutable `YYYYMMDD` daily build dates.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

## [2026-11-26]

### Automated Daily Build
- MariaDB 11.8 rebuilt at `11.8.10` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:19560065cbf8db2b94db12c7c4e87b29d00bd267e040e441bdd463732e3f2138`)
- MariaDB 12.3 rebuilt at `12.3.4` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:3dea0afb75ad6df0f7a5ff79bbab5babd9de7dc8ae695e6aa58b0248c9665a86`)

### Security
- Trivy and Grype (SPDX SBOM) gates verified: **0 fixable vulnerabilities of any severity** across `linux/amd64` and `linux/arm64`; Cosign OIDC signed with SLSA Build L3 provenance.
---

---

## [2026-11-25]

### Automated Daily Build
- MariaDB 11.8 rebuilt at `11.8.10` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:6c1692f35612a285f13a6c8018a5b32c97f40dea3fc65cb0e16da9cdca05167a`)
- MariaDB 12.3 rebuilt at `12.3.4` on Debian `13.8` (multi-arch `amd64`/`arm64`, `dgcosenza/mariadb@sha256:7456a61a9dfc7b14678d327685b06dd6f14a16724eb9cc9da51f8adae55a34f8`)

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
