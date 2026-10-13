#!/usr/bin/env bash
# Run this script on the server after copying the artifacts.
# Prerequisites: openjdk-21-jre, apache2, certbot, python3-certbot-apache installed.
set -euo pipefail

SUBDOMAIN="${1:?Usage: deploy.sh YOUR-SUBDOMAIN.duckdns.org}"
JAR_PATH="${2:?Usage: deploy.sh <subdomain> <path-to-jar>}"
DIST_PATH="${3:?Usage: deploy.sh <subdomain> <jar> <path-to-dist>}"

# --- backend ---
sudo mkdir -p /opt/enterprise-risk-api
sudo cp "$JAR_PATH" /opt/enterprise-risk-api/app.jar
id riskapi &>/dev/null || sudo useradd --system --no-create-home riskapi
sudo chown -R riskapi:riskapi /opt/enterprise-risk-api

sudo cp enterprise-risk-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now enterprise-risk-api

# --- frontend ---
sudo mkdir -p /var/www/enterprise-risk-frontend
sudo cp -r "$DIST_PATH"/. /var/www/enterprise-risk-frontend/

# --- apache ---
sudo a2enmod ssl proxy proxy_http rewrite headers
sudo cp enterprise-risk.conf /etc/apache2/sites-available/
sudo sed -i "s/YOUR-SUBDOMAIN.duckdns.org/$SUBDOMAIN/g" \
    /etc/apache2/sites-available/enterprise-risk.conf
sudo a2ensite enterprise-risk.conf
sudo apachectl configtest
sudo systemctl reload apache2

# --- TLS ---
sudo certbot --apache -d "$SUBDOMAIN"
echo "Done. Test renewal with: sudo certbot renew --dry-run"
