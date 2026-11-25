#!/usr/bin/env bash
# Smoke test for mariadb-docker image
# Verifies: container starts, healthcheck passes, non-root execution, service answers, negative test

set -euo pipefail

IMAGE="${1:-dgcosenza/mariadb:ci-candidate}"
MARIADB_MAJOR="${2:-11.8}"

echo "=== Smoke testing ${IMAGE} (MariaDB ${MARIADB_MAJOR}) ==="

# Generate random passwords for test
ROOT_PASSWORD="$(openssl rand -base64 24)"
USER_PASSWORD="$(openssl rand -base64 24)"
DATABASE="testdb"
USER="testuser"

TMPDATA="$(mktemp -d)"
TMPCONFIG="$(mktemp -d)"
chmod 777 "${TMPDATA}" "${TMPCONFIG}"

cleanup() {
    docker rm -f mariadb-smoke >/dev/null 2>&1 || true
    rm -rf "${TMPDATA}" "${TMPCONFIG}"
}
trap cleanup EXIT

echo "Starting container..."
docker run -d --name mariadb-smoke \
    --security-opt no-new-privileges:true \
    -p 127.0.0.1:13306:3306 \
    -e MARIADB_ROOT_PASSWORD="${ROOT_PASSWORD}" \
    -e MARIADB_DATABASE="${DATABASE}" \
    -e MARIADB_USER="${USER}" \
    -e MARIADB_PASSWORD="${USER_PASSWORD}" \
    -v "${TMPDATA}:/var/lib/mysql" \
    -v "${TMPCONFIG}:/etc/mysql/conf.d" \
    "${IMAGE}"

echo "Waiting for healthcheck to pass..."
for i in {1..60}; do
    if docker exec mariadb-smoke healthcheck.sh --connect --innodb_initialized >/dev/null 2>&1; then
        echo "Healthcheck passed"
        break
    fi
    sleep 2
    if [ "$i" -eq 60 ]; then
        echo "ERROR: Healthcheck never passed"
        docker logs mariadb-smoke
        exit 1
    fi
done

echo "Verifying non-root execution (UID 999)..."
UID_ACTUAL="$(docker exec mariadb-smoke id -u)"
if [ "${UID_ACTUAL}" != "999" ]; then
    echo "ERROR: Container running as UID ${UID_ACTUAL}, expected 999 (mysql)"
    exit 1
fi
echo "OK: Running as UID ${UID_ACTUAL} (mysql)"

echo "Verifying MariaDB connection and basic queries..."
# Test root connection
docker exec mariadb-smoke mariadb -uroot -p"${ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null
echo "OK: Root connection works"

# Test user connection
docker exec mariadb-smoke mariadb -u"${USER}" -p"${USER_PASSWORD}" "${DATABASE}" -e "SELECT 1;" >/dev/null
echo "OK: User connection works"

# Test database creation
docker exec mariadb-smoke mariadb -uroot -p"${ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS smoke_test;" >/dev/null
echo "OK: Database creation works"

# Test table creation and data
docker exec mariadb-smoke mariadb -uroot -p"${ROOT_PASSWORD}" smoke_test -e "
    CREATE TABLE IF NOT EXISTS test (id INT PRIMARY KEY, val VARCHAR(255));
    INSERT INTO test (id, val) VALUES (1, 'hello') ON DUPLICATE KEY UPDATE val='hello';
    SELECT * FROM test;
" | grep -q "hello"
echo "OK: Table operations work"

# Test mariadb-backup binary exists
docker exec mariadb-smoke mariadb-backup --version >/dev/null
echo "OK: mariadb-backup binary present"

# Negative test: healthcheck should fail on wrong socket/port
echo "Running negative healthcheck test..."
if docker exec mariadb-smoke healthcheck.sh --connect --datadir=/nonexistent 2>/dev/null; then
    echo "ERROR: Healthcheck unexpectedly passed on nonexistent datadir"
    exit 1
fi
echo "OK: Negative healthcheck test passed (correctly failed)"

# Verify data persistence by checking datadir ownership
DATADIR_OWNER="$(docker exec mariadb-smoke stat -c '%U:%G' /var/lib/mysql)"
if [ "${DATADIR_OWNER}" != "mysql:mysql" ]; then
    echo "ERROR: Datadir ownership is ${DATADIR_OWNER}, expected mysql:mysql"
    exit 1
fi
echo "OK: Datadir ownership correct (${DATADIR_OWNER})"

# Verify config directory permissions
CONFIGDIR_PERMS="$(docker exec mariadb-smoke stat -c '%a' /etc/mysql/conf.d)"
if [ "${CONFIGDIR_PERMS}" != "750" ] && [ "${CONFIGDIR_PERMS}" != "755" ]; then
    echo "WARNING: Config dir permissions are ${CONFIGDIR_PERMS}"
fi
echo "OK: Config directory accessible"

# Verify no world-writable files in /var/lib/mysql (except socket)
WORLD_WRITABLE="$(docker exec mariadb-smoke find /var/lib/mysql -type f -perm -o=w 2>/dev/null | grep -v '\.sock$' | head -5)"
if [ -n "${WORLD_WRITABLE}" ]; then
    echo "WARNING: World-writable files found in datadir:"
    echo "${WORLD_WRITABLE}"
fi

echo ""
echo "=== All smoke tests passed for ${IMAGE} ==="