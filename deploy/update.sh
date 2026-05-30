#!/bin/bash
# Run on server to pull updates: bash /var/www/trackify/deploy/update.sh
set -e

cd /var/www/trackify
git pull origin main
cd backend
docker compose up -d --build
echo "✓ Updated"
