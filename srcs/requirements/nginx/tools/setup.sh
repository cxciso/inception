#!/bin/bash
set -e

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "[nginx] Generating self-signed certificate for ${DOMAIN_NAME}..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out    /etc/nginx/ssl/inception.crt \
        -subj   "/C=CH/L=Lausanne/O=42/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/templates/inception.conf.template \
    > /etc/nginx/conf.d/inception.conf

echo "[nginx] Starting nginx..."
exec nginx -g "daemon off;"
