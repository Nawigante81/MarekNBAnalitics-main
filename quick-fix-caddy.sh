#!/bin/bash

# Quick manual fix for Caddyfile - run this directly on your Pi
# This will directly edit the existing Caddyfile to fix the logging issue

set -e

echo "Fixing Caddyfile logging configuration..."

# Create a temporary fixed version
sudo sed -i '/rotate {/,/}/c\
        # Log rotation removed - use system logrotate instead' /etc/caddy/Caddyfile

# Also remove any remaining rotate-related lines
sudo sed -i '/size 50mb/d' /etc/caddy/Caddyfile
sudo sed -i '/keep 3/d' /etc/caddy/Caddyfile  
sudo sed -i '/keep_for 168h/d' /etc/caddy/Caddyfile

# Fix the log block structure
sudo sed -i 's|output file /var/log/caddy/nba-analytics.log {|output file /var/log/caddy/nba-analytics.log|' /etc/caddy/Caddyfile

# Remove extra closing brace if it exists
sudo sed -i '/# Log rotation removed/,/level WARN/{/^        }$/d}' /etc/caddy/Caddyfile

echo "Validating fixed Caddyfile..."
if sudo caddy validate --config /etc/caddy/Caddyfile; then
    echo "✅ Caddyfile is now valid!"
    echo "Restarting Caddy service..."
    sudo systemctl restart caddy.service
    sleep 2
    if sudo systemctl is-active --quiet caddy.service; then
        echo "✅ Caddy service is now running!"
        sudo systemctl status caddy.service --no-pager -l
    else
        echo "❌ Caddy service still not running"
        sudo journalctl -xeu caddy.service --no-pager -n 10
    fi
else
    echo "❌ Caddyfile still has issues"
    echo "Current Caddyfile content around the log section:"
    sudo grep -A 10 -B 5 "log {" /etc/caddy/Caddyfile
fi