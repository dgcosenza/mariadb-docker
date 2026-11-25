# Third-Party Notices

This image bundles software from the following upstream projects. Each component retains its original license.

## MariaDB Server

- **License:** GPL-2.0-only
- **Source:** Official MariaDB Debian 13 (`trixie`) APT repository (`https://archive.mariadb.org/`)
- **Upstream repository:** https://github.com/MariaDB/server
- **Full license text:** https://github.com/MariaDB/server/blob/11.8/COPYING

Redistribution of MariaDB Server binaries is permitted under the GNU General Public License, version 2.

## MariaDB Docker Entrypoint & Healthcheck

- **License:** GPL-2.0-only
- **Source:** https://github.com/MariaDB/mariadb-docker (`docker-entrypoint.sh`, `healthcheck.sh`)

## gosu

- **License:** MIT
- **Source:** https://github.com/tianon/gosu (rebuilt from source with the latest patched Go toolchain)
- **Full license text:** https://github.com/tianon/gosu/blob/master/LICENSE

## Debian 13 (`trixie`) Base Packages

- **License:** Various DFSG-compatible open-source licenses
- **Source:** https://deb.debian.org/debian/

---

This repository's own build definitions, CI workflows, tests, and documentation are licensed under the MIT License — Copyright (c) 2026 Daniel G. Cosenza from FNX Labs (see [LICENSE](LICENSE)).
