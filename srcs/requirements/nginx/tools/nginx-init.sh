#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"

mkdir -p "${SSL_DIR}"

if [ ! -f "${SSL_DIR}/server.crt" ]; then
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "${SSL_DIR}/server.key" \
    -out "${SSL_DIR}/server.crt" \
    -subj "/CN=${DOMAIN_NAME}"
fi

exec nginx -g 'daemon off;'