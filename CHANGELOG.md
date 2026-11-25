# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
for the *image tags* (MariaDB version + build date). The repository itself uses
calendar versioning for daily builds.

## [Unreleased]

### Added
- Initial release of hardened MariaDB image on Debian 13 (trixie)
- Matrix build for MariaDB 11.8 (LTS) and 12.3 (LTS)
- gosu rebuilt from source with Go 1.25.7+ to eliminate fixable CVEs
- Daily CI with Trivy (hard gate), Grype, SBOM generation
- Full compatibility with upstream docker-library/mariadb entrypoint
- Non-root execution (UID 999, mysql user)
- OCI labels, healthcheck, initialization script support

## [11.8.10-20261124] - 2026-11-24
## [12.3.4-20261124] - 2026-11-24

### Added
- First published build
- MariaDB 11.8.10 (LTS) and 12.3.4 (LTS) from official apt repository
- Debian 13 (trixie-slim) base, fully upgraded at build time
- gosu 1.20 rebuilt with Go 1.25.7 (fixes 26 CVEs in stdlib)
- Trivy scan: 0 fixable Critical/High
- Grype scan: 0 fixable Critical/High

### Security
- Eliminated 26 fixable vulnerabilities (1 CRITICAL, 25 HIGH) in gosu stdlib by rebuilding with Go 1.25.7
- Base OS (Debian 13) fully patched at build time

### Compatibility
- Drop-in replacement for `mariadb:11.8` and `mariadb:12.3` from Docker Hub
- Same environment variables, volumes, ports, UID/GID, healthcheck
- Entry point and healthcheck scripts from upstream MariaDB Docker (11.8 branch)