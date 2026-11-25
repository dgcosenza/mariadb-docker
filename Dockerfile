# syntax=docker/dockerfile:1.7
# Hardened MariaDB on Debian 13 (trixie) — builds for 11.8 (LTS) and 12.3 (LTS)
# Upstream: https://github.com/MariaDB/mariadb-docker
# Maintainer: Daniel G. Cosenza from FNX Labs

# ---- Build args (overridden daily by CI) ----
ARG GO_BASE=golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee
ARG DEBIAN_BASE=debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0
ARG MARIADB_MAJOR=11.8
ARG MARIADB_VERSION=11.8.10
ARG GOSU_VERSION=1.20
ARG GO_VERSION=1.27.4
# MariaDB Signing Key <signing-key@mariadb.org>
ARG GPG_KEYS=177F4010FE56CA3336300305F1656F24C74CD1D8
ARG IMAGE_CREATED=1970-01-01T00:00:00Z
ARG IMAGE_REVISION=dev
ARG IMAGE_SOURCE=https://github.com/dgcosenza/mariadb-docker

# ---- Stage 1: Build gosu from source with a patched Go toolchain ----
FROM ${GO_BASE} AS gosu-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG GOSU_VERSION
ARG TARGETOS=linux
ARG TARGETARCH

WORKDIR /src
RUN git clone --depth 1 --branch "${GOSU_VERSION}" https://github.com/tianon/gosu.git /src/gosu

WORKDIR /src/gosu
RUN set -eux; \
    CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
        go build -trimpath -ldflags="-s -w" -o /out/gosu .; \
    go test ./...

# ---- Stage 2: Runtime image ----
FROM ${DEBIAN_BASE} AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG MARIADB_MAJOR
ARG MARIADB_VERSION
ARG GOSU_VERSION
ARG GO_VERSION
ARG GPG_KEYS
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="MariaDB on Debian 13 (trixie)" \
      org.opencontainers.image.description="Hardened MariaDB container image on Debian 13 (trixie-slim) from the official MariaDB APT repository, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.version="${MARIADB_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/mariadb" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.licenses="GPL-2.0-only AND MIT" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      io.github.dgcosenza.mariadb.major="${MARIADB_MAJOR}" \
      io.github.dgcosenza.mariadb.version="${MARIADB_VERSION}" \
      io.github.dgcosenza.mariadb.gosu="${GOSU_VERSION}" \
      io.github.dgcosenza.mariadb.go="${GO_VERSION}"

# Install freshly compiled gosu (zero Go stdlib CVEs)
COPY --from=gosu-builder --chmod=0755 /out/gosu /usr/local/bin/gosu

# Create mysql user, upgrade base OS, verify MariaDB APT key, and install MariaDB
RUN set -eux; \
    groupadd --system --gid 999 mysql; \
    useradd --system --uid 999 --gid 999 --home-dir /var/lib/mysql --shell /bin/bash --comment 'MariaDB server' mysql; \
    gosu --version; \
    gosu nobody true; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gpgv \
        libjemalloc2 \
        libtcmalloc-minimal4t64 \
        pwgen \
        tzdata \
        xz-utils \
        zstd \
        socat; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends curl gpg; \
    \
    install -d -m 0755 /etc/apt/keyrings; \
    KEY_TMP="$(mktemp)"; \
    curl -fsSL "https://mariadb.org/mariadb_release_signing_key.pgp" -o "${KEY_TMP}"; \
    FPR="$(gpg --show-keys --with-colons "${KEY_TMP}" | awk -F: '/^fpr:/ { print $10; exit }')"; \
    if [ "${FPR}" != "${GPG_KEYS}" ]; then \
        echo "ERROR: MariaDB signing key fingerprint mismatch: got ${FPR}, expected ${GPG_KEYS}" >&2; \
        exit 1; \
    fi; \
    gpg --batch --dearmor -o /etc/apt/keyrings/mariadb.gpg "${KEY_TMP}"; \
    chmod 0644 /etc/apt/keyrings/mariadb.gpg; \
    rm -f "${KEY_TMP}"; \
    \
    case "${MARIADB_MAJOR}" in \
        11.8) PKG="mariadb-server" ;; \
        12.3) PKG="mariadb-server-galera" ;; \
        *) echo "Unsupported MARIADB_MAJOR: ${MARIADB_MAJOR}" >&2; exit 1 ;; \
    esac; \
    MARIADB_DEB_VERSION="1:${MARIADB_VERSION}+maria~deb13"; \
    echo "deb [signed-by=/etc/apt/keyrings/mariadb.gpg] https://archive.mariadb.org/mariadb-${MARIADB_VERSION}/repo/debian/ trixie main main/debug" \
        > /etc/apt/sources.list.d/mariadb.list; \
    { \
        echo 'Package: *'; \
        echo 'Pin: release o=MariaDB'; \
        echo 'Pin-Priority: 999'; \
    } > /etc/apt/preferences.d/mariadb; \
    \
    apt-get update; \
    { \
        echo "mariadb-server mysql-server/root_password password 'unused'"; \
        echo "mariadb-server mysql-server/root_password_again password 'unused'"; \
    } | debconf-set-selections; \
    mkdir -p /var/lib/mysql/mysql; touch /var/lib/mysql/mysql/user.frm; \
    apt-get install -y --no-install-recommends \
        "${PKG}=${MARIADB_DEB_VERSION}" \
        "mariadb-backup=${MARIADB_DEB_VERSION}"; \
    \
    apt-mark auto '.*' > /dev/null; \
    printf '%s\n' "${savedAptMark}" | xargs -r apt-mark manual > /dev/null; \
    apt-mark manual "${PKG}" mariadb-backup > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false curl gpg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    \
    # Purge postinst skeleton and recreate runtime directories with proper ownership \
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /run/mysqld /etc/mysql/conf.d /docker-entrypoint-initdb.d; \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld /etc/mysql/conf.d /docker-entrypoint-initdb.d; \
    chmod 1777 /run/mysqld; \
    \
    # Comment out host-specific directives \
    find /etc/mysql/ -name '*.cnf' -print0 \
        | xargs -0 grep -lZE '^(bind-address|log|user\s)' \
        | xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" > /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    if [ -L /etc/mysql/my.cnf ]; then \
        sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
    fi; \
    \
    mariadbd --version; \
    mariadb-backup --version

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

ENV LANG=C.UTF-8 \
    GOSU_VERSION="${GOSU_VERSION}" \
    MARIADB_UPSTREAM_VERSION="${MARIADB_VERSION}" \
    MARIADB_VERSION="1:${MARIADB_VERSION}+maria~deb13"

VOLUME /var/lib/mysql

EXPOSE 3306

USER mysql:mysql

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["healthcheck.sh", "--connect", "--innodb_initialized"]
