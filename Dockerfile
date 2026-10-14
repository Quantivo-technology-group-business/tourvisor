# ==========================================
# Stage 1: Build & Vendor Dependencies
# ==========================================
FROM php:8.2-fpm-alpine AS builder

WORKDIR /var/www/html/bc-cms

# Install system dependencies and extension installer
RUN apk add --no-cache \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev

# Add Docker PHP extension installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required PHP extensions
RUN install-php-extensions \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    zip \
    opcache \
    redis

# Copy Composer binary
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy only dependency definitions first for layer caching
COPY bc-cms/composer.json bc-cms/composer.lock ./
COPY bc-cms/packages ./packages

# Install dependencies (no dev dependencies for production)
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

# ==========================================
# Stage 2: Final Production Runtime Image
# ==========================================
FROM php:8.2-fpm-alpine AS app

WORKDIR /var/www/html

# Install runtime dependencies and tools
RUN apk add --no-cache \
    bash \
    curl \
    supervisor \
    libpng \
    libjpeg-turbo \
    freetype \
    icu-libs \
    libzip \
    oniguruma

# Add Docker PHP extension installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install runtime extensions matching builder
RUN install-php-extensions \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    zip \
    opcache \
    redis

# Copy custom configurations
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy application source code
COPY --chown=www-data:www-data . /var/www/html

# Copy pre-built vendor packages from builder stage
COPY --chown=www-data:www-data --from=builder /var/www/html/bc-cms/vendor /var/www/html/bc-cms/vendor

# Default environment variables for supervisor
ENV ENABLE_WORKER=false \
    ENABLE_SCHEDULER=false \
    AUTO_MIGRATE=false \
    CACHE_CONFIG=false \
    APP_ENV=production

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
