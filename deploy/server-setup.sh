#!/bin/bash
# Run this once on the server: bash server-setup.sh
set -e

DOMAIN="api.trackify.vision2co.de"
DEPLOY_DIR="/var/www/trackify"
REPO="git@github.com:avn-dev/trackify.git"

echo "==> Installing Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "$USER"
fi

echo "==> Installing Docker Compose plugin..."
apt-get install -y docker-compose-plugin 2>/dev/null || true

echo "==> Installing Certbot..."
apt-get update -q
apt-get install -y nginx certbot python3-certbot-nginx

echo "==> Cloning repo..."
git clone "$REPO" "$DEPLOY_DIR" 2>/dev/null || (cd "$DEPLOY_DIR" && git pull origin main)

echo "==> Setting up backend .env..."
cd "$DEPLOY_DIR/backend"
if [ ! -f .env ]; then
    cp .env.example .env
    # Generate a fresh APP_KEY inside the container
    docker compose run --rm app php artisan key:generate --force
fi

echo "==> Building and starting container..."
docker compose up -d --build

echo "==> Waiting for container..."
sleep 5

echo "==> Setting up NGINX site..."
cp "$DEPLOY_DIR/deploy/nginx-site.conf" /etc/nginx/sites-available/trackify-api
ln -sf /etc/nginx/sites-available/trackify-api /etc/nginx/sites-enabled/trackify-api
nginx -t && systemctl reload nginx

echo "==> Obtaining SSL certificate..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@trackify.app

echo ""
echo "✓ Done! API running at https://$DOMAIN"
echo "  docker compose -f $DEPLOY_DIR/backend/docker-compose.yml logs -f"
