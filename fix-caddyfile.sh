#!/bin/bash

# Fix Caddyfile logging configuration
# This script corrects the invalid log rotation syntax in the Caddyfile

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Detect Pi IP address
PI_IP=$(hostname -I | awk '{print $1}')
if [ -z "$PI_IP" ]; then
    PI_IP="192.168.100.196"  # fallback
fi

print_step "Fixing Caddyfile logging configuration..."

# Create corrected Caddyfile
cat > /tmp/Caddyfile.fixed << EOF
# NBA Analytics - Raspberry Pi 4 ARM64 Optimized Caddyfile
$PI_IP {
    # ARM64/Pi4 optimizations - reduced worker processes

    # Security headers (lighter for Pi)
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        -Server
    }

    # Lighter compression for ARM64
    encode {
        gzip 6
        # Skip zstd on ARM64 for better performance
    }

    # Health check endpoint
    handle /health {
        respond "healthy - Pi4 ARM64" 200
        header Content-Type "text/plain"
    }

    # Backend API proxy with ARM64 timeouts
    handle /api/* {
        reverse_proxy 127.0.0.1:8000 {
            # Longer timeouts for ARM64
            health_uri /health
            health_interval 45s
            health_timeout 15s

            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_addr}
            header_up X-Forwarded-For {remote_addr}
            header_up X-Forwarded-Proto {scheme}

            # ARM64 timeout settings
            transport http {
                dial_timeout 10s
                response_header_timeout 30s
            }
        }
    }

    # Frontend static files
    handle {
        try_files {path} /index.html
        root * /var/www/nba-analytics/dist
        file_server

        # Cache static assets (lighter caching for Pi)
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg
        }
        header @static {
            Cache-Control "public, max-age=86400"
        }
    }

    # Simplified logging configuration for ARM64
    log {
        output file /var/log/caddy/nba-analytics.log
        level WARN
    }
}

# Local access
127.0.0.1, localhost {
    handle /api/* {
        reverse_proxy 127.0.0.1:8000
    }

    handle {
        reverse_proxy 127.0.0.1:5173
    }
}
EOF

# Backup current Caddyfile
if [ -f /etc/caddy/Caddyfile ]; then
    print_status "Backing up current Caddyfile..."
    BACKUP_NAME="Caddyfile.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp /etc/caddy/Caddyfile "/etc/caddy/$BACKUP_NAME"
fi

# Copy the fixed Caddyfile
print_step "Installing corrected Caddyfile..."
sudo cp /tmp/Caddyfile.fixed /etc/caddy/Caddyfile
sudo chown caddy:caddy /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile
rm /tmp/Caddyfile.fixed

# Validate the corrected Caddyfile
print_step "Validating corrected Caddyfile..."
if sudo caddy validate --config /etc/caddy/Caddyfile; then
    print_status "✅ Caddyfile validation successful!"
else
    print_error "❌ Caddyfile validation failed"
    print_warning "Restoring backup..."
    for backup_file in /etc/caddy/Caddyfile.backup.*; do
        if [ -f "$backup_file" ]; then
            sudo cp "$backup_file" /etc/caddy/Caddyfile
            break
        fi
    done
    exit 1
fi

# Restart Caddy service
print_step "Restarting Caddy service..."
sudo systemctl restart caddy.service

# Check Caddy service status
sleep 3
if sudo systemctl is-active --quiet caddy.service; then
    print_status "✅ Caddy service is running successfully!"
    print_status "✅ Caddyfile fix completed successfully!"
    
    # Show service status
    print_step "Caddy service status:"
    sudo systemctl status caddy.service --no-pager -l
else
    print_error "❌ Caddy service failed to start"
    print_warning "Checking logs..."
    sudo journalctl -xeu caddy.service --no-pager -n 20
    exit 1
fi

print_status "✅ All services should now be running properly!"
print_status "You can access the application at: http://$PI_IP"