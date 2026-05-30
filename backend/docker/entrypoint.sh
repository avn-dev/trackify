#!/bin/bash
set -e

# Ensure SQLite database file exists
if [ ! -f /var/www/html/database/database.sqlite ]; then
    touch /var/www/html/database/database.sqlite
fi
chown www-data:www-data /var/www/html/database/database.sqlite
chmod 664 /var/www/html/database/database.sqlite

# Run migrations
php artisan migrate --force --no-interaction

# Cache for production performance
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start supervisor (manages both nginx + php-fpm)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
