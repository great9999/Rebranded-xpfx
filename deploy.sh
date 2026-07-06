#!/bin/bash
set -e
echo "==> Pulling latest code"
git pull origin main

echo "==> Installing dependencies"
npm install --workspaces

echo "==> Building all workspaces"
npm run build --workspace=artifacts/api-server
npm run build --workspace=artifacts/nextrade
npm run build --workspace=artifacts/admin-portal

echo "==> Running database migrations"
cd artifacts/api-server && npx prisma migrate deploy && cd ../.. || true

echo "==> Copying frontend builds"
mkdir -p /var/www/xpresspro/nextrade /var/www/xpresspro/admin-portal
cp -r artifacts/nextrade/dist /var/www/xpresspro/nextrade 2>/dev/null || true
cp -r artifacts/admin-portal/dist /var/www/xpresspro/admin-portal 2>/dev/null || true

echo "==> Reloading API with PM2 (zero-downtime)"
cd artifacts/api-server
pm2 reload ecosystem.config.js --env production || pm2 start ecosystem.config.js --env production
cd ../..

echo "==> Reloading Nginx"
sudo nginx -t && sudo systemctl reload nginx

echo "==> Health check"
sleep 5
curl --fail http://localhost:8080/healthz || (pm2 rollback xpresspro-api && exit 1)

echo "==> Deployment complete"