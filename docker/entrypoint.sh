#!/bin/sh
set -e

CMS_DIR="/var/www/html/bc-cms"
PUBLIC_DIR="/var/www/html/public_html"

echo "==> Initializing Tourvisor Application Container..."

# Ensure .env exists in bc-cms
if [ ! -f "$CMS_DIR/.env" ]; then
    if [ -f "$CMS_DIR/.env.example" ]; then
        echo "==> Creating $CMS_DIR/.env from .env.example..."
        cp "$CMS_DIR/.env.example" "$CMS_DIR/.env"
    fi
fi

# Ensure storage directories exist
mkdir -p "$CMS_DIR/storage/framework/cache/data" \
         "$CMS_DIR/storage/framework/sessions" \
         "$CMS_DIR/storage/framework/views" \
         "$CMS_DIR/storage/logs" \
         "$CMS_DIR/storage/app/public" \
         "$CMS_DIR/bootstrap/cache" \
         "$PUBLIC_DIR/uploads"

# Fix storage permissions
chown -R www-data:www-data "$CMS_DIR/storage" "$CMS_DIR/bootstrap/cache" "$PUBLIC_DIR/uploads" 2>/dev/null || true
chmod -R 775 "$CMS_DIR/storage" "$CMS_DIR/bootstrap/cache" "$PUBLIC_DIR/uploads" 2>/dev/null || true

# Generate APP_KEY if missing
if [ -f "$CMS_DIR/.env" ] && ! grep -q "^APP_KEY=base64:" "$CMS_DIR/.env"; then
    echo "==> Generating Application Encryption Key..."
    php "$CMS_DIR/artisan" key:generate --force || true
fi

# Auto migrate if requested
if [ "$AUTO_MIGRATE" = "true" ]; then
    echo "==> Running database migrations..."
    php "$CMS_DIR/artisan" migrate --force || true
fi

# Cache configuration & routes in production if enabled
if [ "$APP_ENV" = "production" ] && [ "$CACHE_CONFIG" = "true" ]; then
    echo "==> Caching Laravel configuration and routes..."
    php "$CMS_DIR/artisan" config:cache || true
    php "$CMS_DIR/artisan" route:cache || true
    php "$CMS_DIR/artisan" view:cache || true
fi

echo "==> Starting process: $@"
exec "$@"
