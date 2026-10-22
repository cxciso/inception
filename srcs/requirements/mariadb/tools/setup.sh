#!/bin/bash
set -e

DB_NAME=$(cat "$MYSQL_DATABASE_FILE")
DB_USER=$(cat "$MYSQL_USER_FILE")
DB_PASS=$(cat "$MYSQL_PASSWORD_FILE")
ROOT_PASS=$(cat "$MYSQL_ROOT_PASSWORD_FILE")

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

if [ ! -d "/var/lib/mysql/$DB_NAME" ]; then
    mysqld --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS';
FLUSH PRIVILEGES;
EOF
fi

exec mysqld --user=mysql
