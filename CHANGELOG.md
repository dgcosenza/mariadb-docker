# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Image tags track official MariaDB release versions plus immutable `YYYYMMDD` daily build dates.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

---

## [2026-11-25]

### Changed
- MariaDB 11.8 rebuilt at `11.8.10` on Debian `13.8` (`dgcosenza/mariadb@sha256:10c55123f9fb80e0de5f3e3f5e957ca15bbd81398d1b5e689d9836ab5296fd3e`)
- MariaDB 12.3 rebuilt at `12.3.4` on Debian `13.8` (`dgcosenza/mariadb@sha256:bb12604a21a9bf6aa418a735f1fca45235725e282e9d0c7d9c62a883c04b19dd`)

### Security
- Trivy and Grype gates verified: 0 fixable Critical/High vulnerabilities.

## [2026-11-24]

### Added
- Initial hardened MariaDB 11.8 LTS (`11.8.10`) and 12.3 LTS (`12.3.4`) images on Debian 13 (`trixie-slim`) using the official GPG-verified MariaDB Debian 13 APT repository.
- Source-rebuilt `gosu 1.20` using Go `1.27.4` (`golang:1.27.4-trixie`) to eliminate fixable Go stdlib vulnerabilities present in prebuilt upstream binaries.
- Full 7-step automated daily CI pipeline: upstream version/release-notes tracking, clean `--no-cache` rebuilds, Trivy + Grype hard gates (0 fixable Critical/High), SPDX-JSON SBOM + provenance, functional smoke tests, automated docs/changelog/Docker Hub sync, and `ci-failure` issue alerting.
- Full drop-in compatibility with upstream `docker-library/mariadb` environment variables, `/docker-entrypoint-initdb.d`, UID/GID `999:999`, and `healthcheck.sh`.

### Security
- Eliminated 26 fixable vulnerabilities (1 Critical, 25 High) found in upstream `mariadb:11.8` / `mariadb:12.3` (`gosu` Go 1.24.6 stdlib).
- Base Debian 13 (`trixie-slim`) packages upgraded at build time; verified 0 fixable Critical/High in Trivy and Grype.
