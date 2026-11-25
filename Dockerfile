# syntax=docker/dockerfile:1.7
# Hardened MariaDB on Debian 13 (trixie) — builds for 11.8 (LTS) and 12.3 (LTS)
# Upstream: https://github.com/MariaDB/mariadb-docker
# Maintainer: Daniel G. Cosenza from FNX Labs

# ---- Build args (overridden by CI daily) ----
ARG DEBIAN_VERSION=trixie-slim
ARG MARIADB_MAJOR=11.8
ARG MARIADB_VERSION=11.8.10
ARG GOSU_VERSION=1.20
ARG GO_VERSION=1.25.7
ARG GPG_KEYS=177F4010FE56CA3336300305F1656F24C74CD1D8
# MariaDB signing key (MariaDB Signing Key <signing-key@mariadb.org>)
# gosu signing key (B42F6819007F00F88E364FD4036A9C25BF357DD4)

# ---- Stage 1: Build gosu from source with fixed Go ----
FROM golang:${GO_VERSION}-${DEBIAN_VERSION} AS gosu-builder

ARG GOSU_VERSION
ARG TARGETARCH

RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 --branch "${GOSU_VERSION}" https://github.com/tianon/gosu.git /src/gosu; \
    cd /src/gosu; \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o gosu .; \
    GOARCH="${TARGETARCH}" go test ./...; \
    mkdir -p /out && cp gosu /out/gosu

# ---- Stage 2: Runtime image ----
FROM debian:${DEBIAN_VERSION} AS runtime

# Build args (re-declared for this stage)
ARG MARIADB_MAJOR
ARG MARIADB_VERSION
ARG GPG_KEYS
ARG DEBIAN_FRONTEND=noninteractive

# OCI labels (populated at build time via CI)
LABEL org.opencontainers.image.title="MariaDB on Debian 13 (trixie)" \
      org.opencontainers.image.description="Hardened, up-to-date MariaDB container image for Debian 13 (trixie), built from official MariaDB apt repository, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/mariadb" \
      org.opencontainers.image.source="https://github.com/dgcosenza/mariadb-docker" \
      org.opencontainers.image.documentation="https://github.com/dgcosenza/mariadb-docker#readme" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.licenses="GPL-2.0-only" \
      org.opencontainers.image.base.name="debian:trixie-slim"

# Create mysql user/group with consistent IDs (matching upstream docker-library convention)
RUN groupadd --system --gid 999 mysql \
    && useradd --system --uid 999 --gid 999 --home-dir /var/lib/mysql --shell /bin/bash --comment 'MariaDB server' mysql \
    && install -d -m 0750 -o mysql -g mysql /var/lib/mysql /run/mysqld /docker-entrypoint-initdb.d

# Copy gosu binary from builder
COPY --from=gosu-builder /out/gosu /usr/local/bin/gosu
RUN chmod 0755 /usr/local/bin/gosu && gosu --version && gosu nobody true

# Install runtime dependencies and MariaDB from official apt repository
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gpg \
        gpgv \
        libjemalloc2 \
        libtcmalloc-minimal4t64 \
        pwgen \
        tzdata \
        xz-utils \
        zstd \
        socat \
        procps; \
    rm -rf /var/lib/apt/lists/*; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${GPG_KEYS}"; \
    gpg --batch --export "${GPG_KEYS}" > /etc/apt/trusted.gpg.d/mariadb.gpg; \
    gpgconf --kill all; \
    rm -rf "${GNUPGHOME}"; \
    \
    case "${MARIADB_MAJOR}" in \
        11.8) \
            REPO_URL="https://archive.mariadb.org/mariadb-${MARIADB_VERSION}/repo/ubuntu/ noble main main/debug" \
            PKG="mariadb-server" \
            ;; \
        12.3) \
            REPO_URL="https://archive.mariadb.org/mariadb-${MARIADB_VERSION}/repo/ubuntu/ noble main main/debug" \
            PKG="mariadb-server-galera" \
            ;; \
        *) \
            echo "Unsupported MARIADB_MAJOR: ${MARIADB_MAJOR}" >&2; exit 1 \
            ;; \
    esac; \
    echo "deb ${REPO_URL}" > /etc/apt/sources.list.d/mariadb.list; \
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
    apt-get install -y --no-install-recommends "${PKG}=${MARIADB_VERSION}" mariadb-backup; \
    rm -rf /var/lib/apt/lists/*; \
    \
    # Purge and re-create /var/lib/mysql with appropriate ownership
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /run/mysqld; \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld; \
    chmod 1777 /run/mysqld; \
    \
    # Comment out problematic configuration values
    find /etc/mysql/ -name '*.cnf' -print0 \
        | xargs -0 grep -lZE '^(bind-address|log|user\s)' \
        | xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    # Don't reverse lookup hostnames
    printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" > /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    # Correct includedir order (mariadb.conf.d before conf.d)
    if [ -L /etc/mysql/my.cnf ]; then \
        sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
    fi; \
    \
    # Verify installation
    mariadbd --version; \
    mariadb-backup --version

# Copy entrypoint and healthcheck from upstream (adapted for Debian)
COPY docker-entrypoint.sh /usr/local/bin/
COPY healthcheck.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/healthcheck.sh

# Ensure config directory is writable by mysql for healthcheck config
RUN mkdir -p /etc/mysql/conf.d && chown -R mysql:mysql /etc/mysql/conf.d

ENV LANG=C.UTF-8 \
    MARIADB_VERSION="${MARIADB_VERSION}"

VOLUME /var/lib/mysql

EXPOSE 3306

USER mysql:mysql

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mariadbd"]

# Healthcheck uses the upstream healthcheck.sh with --connect --innodb_initialized
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["healthcheck.sh", "--connect", "--innodb_initialized"]