#!/bin/bash

# Quick Start NBA Analytics with Caddy
set -e

echo "🏀 NBA Analytics - Quick Start with Caddy"

# Check if Caddy is installed
if ! command -v caddy &> /dev/null; then
    echo "❌ Caddy not found. Running full deployment..."
    chmod +x deploy-caddy.sh
    ./deploy-caddy.sh
    exit 0
fi

# Check if services exist
if ! systemctl list-unit-files | grep -q nba-backend; then
    echo "❌ Services not configured. Running full deployment..."
    chmod +x deploy-caddy.sh
    ./deploy-caddy.sh
    exit 0
fi

echo "🚀 Starting NBA Analytics services..."

# Start all services
sudo systemctl start nba-backend nba-frontend caddy

# Wait for startup
echo "⏳ Waiting for services to start..."
sleep 10

# Check status
echo "📊 Service Status:"
for service in nba-backend nba-frontend caddy; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service is running"
    else
        echo "❌ $service failed to start"
        echo "Check logs: sudo journalctl -u $service"
    fi
done

# Health checks
echo ""
echo "❤️ Health Checks:"
if curl -f -s http://localhost/health > /dev/null; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed"
fi

if curl -f -s http://localhost:8000/health > /dev/null; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
fi

echo ""
echo "🌐 Application is running:"
echo "  Frontend: http://localhost"
echo "  Backend:  http://localhost:8000"
echo "  API Docs: http://localhost:8000/docs"
echo ""
echo "🔧 Management: ./caddy-manage.sh"