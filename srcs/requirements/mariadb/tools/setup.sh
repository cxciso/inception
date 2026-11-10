#!/bin/bash
set -e

# Passwords come from Docker secrets (files mounted in /run/secrets)
DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

# Folder for the socket file, and ownership of the data folder (the volume)
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# First start only: the volume is empty, create MariaDB's system tables
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[mariadb] Initializing data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null
fi

# First start only: create the WordPress database and its user
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "[mariadb] Creating database '${MYSQL_DATABASE}' and user '${MYSQL_USER}'..."
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
EOF
fi

echo "[mariadb] Starting server..."
# exec: mysqld replaces this script and becomes PID 1
exec mysqld --user=mysql
