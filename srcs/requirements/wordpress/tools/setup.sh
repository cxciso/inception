#!/bin/bash
set -e

# Passwords come from Docker secrets (files mounted in /run/secrets)
DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
WP_USER_PASS=$(cat /run/secrets/wp_user_password)

cd /var/www/html

# Wait until MariaDB accepts connections (30 tries max, never infinite)
for i in $(seq 1 30); do
    if mariadb -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${DB_PASS}" \
            -e "SELECT 1;" "${MYSQL_DATABASE}" > /dev/null 2>&1; then
        echo "[wordpress] MariaDB is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "[wordpress] MariaDB is not reachable, giving up." >&2
        exit 1
    fi
    echo "[wordpress] Waiting for MariaDB ($i/30)..."
    sleep 2
done

# First start only: the volume has no wp-config.php yet
if [ ! -f wp-config.php ]; then
    echo "[wordpress] Installing WordPress..."

    if [ ! -f wp-load.php ]; then
        wp core download --allow-root
    fi

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost="${MYSQL_HOST}:3306"

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASS}"
fi

# php-fpm runs as www-data: it must own the website files
chown -R www-data:www-data /var/www/html

echo "[wordpress] Starting php-fpm..."
# exec: php-fpm replaces this script and becomes PID 1, -F = stay in foreground
exec php-fpm8.2 -F
