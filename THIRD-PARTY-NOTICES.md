# Third-Party Notices

This image bundles software from the following upstream projects. Each component retains its original license.

## MariaDB Server

**License:** GPL-2.0-only  
**Source:** https://archive.mariadb.org/mariadb-{version}/repo/ubuntu/ (official MariaDB apt repository)  
**Version:** 11.8.10 / 12.3.4 (resolved daily in CI)

```
MariaDB is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; version 2 of the License.

MariaDB is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with MariaDB; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
```

Full license text: https://github.com/MariaDB/server/blob/11.8/COPYING

## gosu

**License:** MIT  
**Source:** https://github.com/tianon/gosu  
**Version:** 1.20 (rebuilt from source with Go 1.25.7 in this image)

```
MIT License

Copyright (c) 2014 Tianon Gravi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Full license text: https://github.com/tianon/gosu/blob/master/LICENSE

## Debian 13 (trixie) Base Packages

**License:** Various (DFSG-compatible)  
**Source:** http://deb.debian.org/debian/  
**Components:** All packages installed from Debian main repository during build

Individual package licenses can be inspected via `apt-cache show <package>` or
https://packages.debian.org/trixie/<package>.

## MariaDB Docker Entrypoint & Healthcheck

**License:** GPL-2.0-only (same as MariaDB Server)  
**Source:** https://github.com/MariaDB/mariadb-docker  
**Version:** 11.8 branch (docker-entrypoint.sh, healthcheck.sh)

These scripts are copied from the upstream MariaDB Docker repository and are
licensed under the same terms as MariaDB Server.

---

**Note:** This repository's own code (Dockerfile, CI workflows, tests, documentation)
is licensed under the MIT License (see [LICENSE](LICENSE)).