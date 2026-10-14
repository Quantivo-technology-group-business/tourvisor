#!/usr/bin/env bash
# ==============================================================================
# Tourvisor - Automated Deployment Script
# Domain: https://tourvisor.quantivogroup.com
# Repository: git@github.com:Quantivo-technology-group-business/tourvisor.git
# ==============================================================================

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/www/wwwroot/tourvisor.quantivogroup.com}"
CMS_DIR="${CMS_DIR:-${PROJECT_DIR}/bc-cms}"
PUBLIC_DIR="${PUBLIC_DIR:-${PROJECT_DIR}/public_html}"
DOMAIN="${DOMAIN:-tourvisor.quantivogroup.com}"
APP_URL="${APP_URL:-https://tourvisor.quantivogroup.com}"
BRANCH="${BRANCH:-main}"
WEB_USER="${WEB_USER:-www}"
WEB_GROUP="${WEB_GROUP:-www}"

# Locate PHP 8.3 Binary
if [ -x "/www/server/php/83/bin/php" ]; then
    PHP_BIN="/www/server/php/83/bin/php -d open_basedir="
elif command -v php >/dev/null 2>&1; then
    PHP_BIN="php"
else
    echo "ERROR: PHP binary not found!" >&2
    exit 1
fi

# Locate Composer
if [ -x "/usr/bin/composer" ]; then
    COMPOSER_BIN="${PHP_BIN} /usr/bin/composer"
elif command -v composer >/dev/null 2>&1; then
    COMPOSER_BIN="composer"
else
    echo "ERROR: Composer binary not found!" >&2
    exit 1
fi

echo "=== [Tourvisor] Pulling latest changes from ${BRANCH} ==="
cd "${PROJECT_DIR}"
git fetch origin "${BRANCH}"
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

echo "=== [Tourvisor] Installing Composer dependencies ==="
cd "${CMS_DIR}"
${COMPOSER_BIN} install --no-interaction --optimize-autoloader

echo "=== [Tourvisor] Running migrations ==="
${PHP_BIN} artisan migrate --force

echo "=== [Tourvisor] Refreshing cache ==="
${PHP_BIN} artisan optimize:clear
${PHP_BIN} artisan cache:clear || true

echo "=== [Tourvisor] Setting permissions ==="
chown -R "${WEB_USER}:${WEB_GROUP}" "${PROJECT_DIR}"
chmod -R 775 "${CMS_DIR}/storage" "${CMS_DIR}/bootstrap/cache"
if [ -d "${PUBLIC_DIR}/uploads" ]; then
    chmod -R 775 "${PUBLIC_DIR}/uploads"
fi

echo "=== [Tourvisor] Reloading Nginx ==="
if [ -x "/etc/init.d/nginx" ]; then
    /etc/init.d/nginx reload
elif command -v systemctl >/dev/null 2>&1; then
    systemctl reload nginx || true
fi

echo "=== [Tourvisor] Health Check ==="
HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "${APP_URL}" || echo "000")
if [ "${HTTP_STATUS}" -eq 200 ] || [ "${HTTP_STATUS}" -eq 302 ]; then
    echo "Deployment successful! Status: ${HTTP_STATUS}"
else
    echo "Deployment warning! Status: ${HTTP_STATUS}"
fi
