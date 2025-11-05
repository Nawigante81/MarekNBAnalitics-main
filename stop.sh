#!/bin/bash

# Stop script for NBA Analytics
set -e

echo "🛑 Stopping NBA Analytics Services..."

# Check which services are running and stop them
if command -v docker-compose &> /dev/null && [ -f "docker-compose.yml" ]; then
    if docker-compose ps | grep -q "Up"; then
        echo "🐳 Stopping Docker services..."
        docker-compose down
        echo "✅ Docker services stopped"
    fi
fi

if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "online"; then
        echo "⚙️ Stopping PM2 services..."
        pm2 delete ecosystem.config.json 2>/dev/null || true
        echo "✅ PM2 services stopped"
    fi
fi

# Stop systemd services if they exist
if systemctl is-active --quiet nba-backend 2>/dev/null; then
    echo "🔧 Stopping systemd services..."
    sudo systemctl stop nba-backend nba-frontend
    echo "✅ Systemd services stopped"
fi

# Kill any remaining processes on ports 8000 and 5173
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔪 Killing process on port 8000..."
    lsof -Pi :8000 -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
fi

if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🔪 Killing process on port 5173..."
    lsof -Pi :5173 -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
fi

echo "✅ All NBA Analytics services stopped!"