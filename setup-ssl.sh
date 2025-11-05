#!/bin/bash

# SSL Setup Script for NBA Analytics on Debian/Ubuntu
set -e

echo "🔒 NBA Analytics - SSL/HTTPS Setup for Debian"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script with sudo"
    exit 1
fi

# Get domain name
read -p "Enter your domain name (e.g., nba-analytics.yourdomain.com): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    print_error "Domain name is required"
    exit 1
fi

# Install Certbot
print_status "Installing Certbot for Let's Encrypt..."
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Stop nginx temporarily
print_status "Stopping Nginx temporarily..."
systemctl stop nginx

# Obtain SSL certificate
print_status "Obtaining SSL certificate for $DOMAIN_NAME..."
certbot certonly --standalone -d $DOMAIN_NAME --email admin@$DOMAIN_NAME --agree-tos --non-interactive

if [ $? -ne 0 ]; then
    print_error "Failed to obtain SSL certificate"
    systemctl start nginx
    exit 1
fi

# Create SSL-enabled Nginx configuration
print_status "Creating SSL-enabled Nginx configuration..."
tee /etc/nginx/sites-available/nba-analytics-ssl > /dev/null <<EOF
# HTTP redirect to HTTPS
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Frontend
    location / {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # API rate limiting
        limit_req zone=api burst=20 nodelay;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
}

# Rate limiting zones
http {
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
}
EOF

# Enable new configuration
print_status "Enabling SSL configuration..."
ln -sf /etc/nginx/sites-available/nba-analytics-ssl /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/nba-analytics

# Test nginx configuration
nginx -t

if [ $? -eq 0 ]; then
    print_status "Starting Nginx with SSL configuration..."
    systemctl start nginx
    systemctl reload nginx
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Setup automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

# Create renewal hook to reload nginx
mkdir -p /etc/letsencrypt/renewal-hooks/deploy
tee /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh > /dev/null <<EOF
#!/bin/bash
systemctl reload nginx
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh

# Test certificate renewal
print_status "Testing certificate renewal..."
certbot renew --dry-run

if [ $? -eq 0 ]; then
    print_status "✅ SSL setup completed successfully!"
    echo ""
    echo "🌐 Your site is now available at: https://$DOMAIN_NAME"
    echo "🔒 SSL certificate will auto-renew every 90 days"
    echo ""
    echo "📋 SSL Management commands:"
    echo "  Check certificate: certbot certificates"
    echo "  Renew manually: certbot renew"
    echo "  Check renewal timer: systemctl status certbot.timer"
    echo ""
    echo "🔧 Nginx commands:"
    echo "  Test config: nginx -t"
    echo "  Reload: systemctl reload nginx"
    echo "  Status: systemctl status nginx"
else
    print_error "Certificate renewal test failed"
    print_warning "SSL is configured but auto-renewal may not work properly"
fi

# Update firewall for HTTPS
if command -v ufw &> /dev/null; then
    print_status "Updating firewall for HTTPS..."
    ufw allow 'Nginx Full'
    ufw --force enable
fi

print_status "🎉 HTTPS setup complete!"
echo ""
echo "Your NBA Analytics app is now secured with SSL!"
echo "Visit: https://$DOMAIN_NAME"