#!/bin/bash

# NBA Analytics - Fix Caddyfile for Caddy v2
# This script fixes common Caddy v1 -> v2 syntax issues

echo "🔧 Fixing Caddyfile for Caddy v2 compatibility..."

# 1. Create log directory with proper permissions
echo "📁 Creating log directory..."
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy
sudo chmod 755 /var/log/caddy

# 2. Backup current Caddyfile
echo "💾 Backing up current Caddyfile..."
sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)"

# 3. Install corrected Caddyfile
echo "📝 Installing corrected Caddyfile..."
sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
# NBA Analytics - Corrected Caddyfile for Caddy v2
# Fixed: removed rotate {}, header_up X-Forwarded-Proto, proper v2 syntax

# Global configuration block
{
    # Global logging configuration
    log {
        output file /var/log/caddy/caddy.log {
            roll_size 10MiB
            roll_keep 5
            roll_keep_for 720h
        }
        format console
    }
}

# Main production domain
192.168.100.196 {
    # Security headers
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"  
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }

    # Enable compression
    encode gzip

    # Health check endpoint
    handle /health {
        respond "healthy" 200 {
            header Content-Type "text/plain"
        }
    }

    # Backend API proxy - FIXED: removed X-Forwarded-Proto
    handle /api/* {
        reverse_proxy localhost:8000 {
            health_uri /health
            health_interval 30s
            health_timeout 10s
            
            # Headers - X-Forwarded-Proto removed (automatic in v2)
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
        }
    }

    # Frontend static files
    handle {
        try_files {path} /index.html
        root * /var/www/nba-analytics/dist
        file_server
        
        # Cache static assets
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2
        }
        header @static {
            Cache-Control "public, max-age=86400, immutable"
        }
    }

    # FIXED: Proper v2 logging syntax with output file
    log {
        output file /var/log/caddy/access.log {
            roll_size 10MiB
            roll_keep 5
            roll_keep_for 720h
        }
        format console
    }
}

# Development/local access
localhost {
    handle /api/* {
        reverse_proxy localhost:8000
    }
    
    handle {
        reverse_proxy localhost:5173
    }
}
EOF

# 4. Format and validate configuration
echo "🔍 Formatting and validating Caddyfile..."
sudo caddy fmt --overwrite /etc/caddy/Caddyfile

if sudo caddy validate --config /etc/caddy/Caddyfile; then
    echo "✅ Caddyfile validation successful!"
    
    # 5. Reload Caddy service
    echo "🔄 Reloading Caddy service..."
    if sudo systemctl reload caddy; then
        echo "✅ Caddy reloaded successfully!"
        
        # Check service status
        echo "📊 Caddy service status:"
        sudo systemctl status caddy --no-pager -l
        
        echo ""
        echo "🎉 Caddyfile has been fixed for Caddy v2!"
        echo "Changes made:"
        echo "- ❌ Removed header_up X-Forwarded-Proto (automatic in v2)"
        echo "- ❌ Removed rotate {} syntax (v1 only)"
        echo "- ✅ Added proper output file with roll_* parameters"
        echo "- ✅ Created /var/log/caddy with proper permissions"
        
        echo ""
        echo "🌐 Your application should now be accessible at:"
        echo "   http://192.168.100.196"
        
    else
        echo "❌ Failed to reload Caddy service"
        echo "📋 Checking logs:"
        sudo journalctl -u caddy --no-pager -n 20
        exit 1
    fi
else
    echo "❌ Caddyfile validation failed!"
    echo "📋 Checking syntax errors:"
    sudo caddy validate --config /etc/caddy/Caddyfile
    exit 1
fi