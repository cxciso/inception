#!/bin/bash
set -e

# Self-signed TLS certificate, created at first start (not stored in the image)
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "[nginx] Generating self-signed certificate for ${DOMAIN_NAME}..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out    /etc/nginx/ssl/inception.crt \
        -subj   "/C=CH/L=Lausanne/O=42/CN=${DOMAIN_NAME}"
fi

# Put the domain name from .env into the config (only ${DOMAIN_NAME} is replaced)
envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/templates/inception.conf.template \
    > /etc/nginx/conf.d/inception.conf

echo "[nginx] Starting nginx..."
# exec: nginx replaces this script and becomes PID 1, daemon off = foreground
exec nginx -g "daemon off;"
