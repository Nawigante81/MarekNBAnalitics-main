#!/bin/bash

# NBA Analytics Deployment Script for Caddy on Debian/Ubuntu
set -e

echo "🏀 NBA Analytics - Caddy Deployment for Debian/Ubuntu"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    print_status "Detected: $OS $VER"
else
    print_error "Cannot detect OS version"
    exit 1
fi

# Update system
print_step "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install basic dependencies
print_step "Installing system dependencies..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    python3-dev \
    python3-pip \
    python3-venv

# Install Node.js 18.x
print_step "Installing Node.js 18.x..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Install Caddy
print_step "Installing Caddy..."
if ! command -v caddy &> /dev/null; then
    # Add Caddy's official repository
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    
    sudo apt-get update
    sudo apt-get install -y caddy
    
    print_status "Caddy installed successfully"
else
    print_status "Caddy is already installed"
fi

CADDY_VERSION=$(caddy version)
print_status "$CADDY_VERSION"

# Setup firewall
print_step "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8000/tcp  # Backend direct access (optional)
    sudo ufw allow 5173/tcp  # Frontend dev server (optional)
    print_status "Firewall configured"
fi

# Create application directory
APP_DIR="/var/www/nba-analytics"
print_step "Setting up application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Copy application files if not already there
if [ "$PWD" != "$APP_DIR" ]; then
    print_step "Copying application files..."
    sudo cp -r . $APP_DIR/
    cd $APP_DIR
    sudo chown -R $USER:$USER $APP_DIR
fi

# Setup environment
if [ ! -f ".env.production" ]; then
    print_warning ".env.production not found. Creating from example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env.production
        print_warning "Please edit .env.production with your configuration"
    fi
fi

# Create directories
mkdir -p logs dist
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy

# Install dependencies
print_step "Installing application dependencies..."

# Frontend
print_status "Installing frontend dependencies..."
npm install

# Backend  
print_status "Installing backend dependencies..."
cd backend
python3 -m pip install --user --upgrade pip
python3 -m pip install --user -r requirements.txt
cd ..

# Build frontend for production
print_step "Building frontend for production..."
npm run build

# Get domain name for Caddyfile
read -p "Enter your domain name (e.g., nba-analytics.yourdomain.com) or press Enter for localhost: " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME="localhost"
    print_warning "Using localhost. For production, rerun with a proper domain."
fi

# Update Caddyfile with actual domain
print_step "Configuring Caddyfile..."
sed -i "s/nba-analytics.yourdomain.com/$DOMAIN_NAME/g" Caddyfile
sed -i "s|/var/www/nba-analytics|$APP_DIR|g" Caddyfile

# Copy Caddyfile to Caddy's directory
sudo cp Caddyfile /etc/caddy/Caddyfile

# Set proper permissions
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

# Validate Caddyfile
print_step "Validating Caddyfile..."
if sudo caddy validate --config /etc/caddy/Caddyfile; then
    print_status "Caddyfile is valid"
else
    print_error "Caddyfile validation failed"
    exit 1
fi

# Setup systemd services for backend and frontend
print_step "Setting up systemd services..."

# Backend service
sudo tee /etc/systemd/system/nba-backend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR/backend
Environment=PATH=/usr/bin:/usr/local/bin:$HOME/.local/bin
EnvironmentFile=$APP_DIR/.env.production
ExecStart=/home/$USER/.local/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (serve built files)
sudo tee /etc/systemd/system/nba-frontend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Frontend Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/npx serve -s dist -l 5173 --no-clipboard
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and start services
print_step "Starting services..."

# Start backend
sudo systemctl enable nba-backend
sudo systemctl start nba-backend

# Start frontend  
sudo systemctl enable nba-frontend
sudo systemctl start nba-frontend

# Start Caddy
sudo systemctl enable caddy
sudo systemctl restart caddy

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 15

# Check service status
print_step "Checking service status..."

services_ok=true

if systemctl is-active --quiet nba-backend; then
    print_status "✅ NBA Backend is running"
else
    print_error "❌ NBA Backend failed to start"
    services_ok=false
fi

if systemctl is-active --quiet nba-frontend; then
    print_status "✅ NBA Frontend is running" 
else
    print_error "❌ NBA Frontend failed to start"
    services_ok=false
fi

if systemctl is-active --quiet caddy; then
    print_status "✅ Caddy is running"
else
    print_error "❌ Caddy failed to start"
    services_ok=false
fi

# Health checks
print_step "Performing health checks..."

# Backend health
if curl -f -s http://localhost:8000/health > /dev/null; then
    print_status "✅ Backend health check passed"
else
    print_error "❌ Backend health check failed"
    services_ok=false
fi

# Frontend via Caddy
if curl -f -s http://localhost/health > /dev/null; then
    print_status "✅ Frontend health check passed"
else
    print_error "❌ Frontend health check failed"  
    services_ok=false
fi

if $services_ok; then
    print_status "🎉 Deployment successful!"
    echo ""
    echo "🌐 Application URLs:"
    if [ "$DOMAIN_NAME" = "localhost" ]; then
        echo "  Frontend: http://localhost"
        echo "  Backend:  http://localhost:8000" 
        echo "  API Docs: http://localhost:8000/docs"
    else
        echo "  Frontend: https://$DOMAIN_NAME"
        echo "  Backend:  https://$DOMAIN_NAME/api"
        echo "  API Docs: https://$DOMAIN_NAME/api/docs"
    fi
    echo ""
    echo "📊 Management Commands:"
    echo "  Service status: sudo systemctl status nba-backend nba-frontend caddy"
    echo "  View logs:      sudo journalctl -u nba-backend -f"
    echo "  Caddy logs:     sudo journalctl -u caddy -f"
    echo "  Restart all:    sudo systemctl restart nba-backend nba-frontend caddy"
    echo "  Caddy reload:   sudo systemctl reload caddy"
    echo ""
    echo "🔧 Configuration files:"
    echo "  Caddyfile:      /etc/caddy/Caddyfile"
    echo "  App directory:  $APP_DIR"
    echo "  Logs:           /var/log/caddy/"
    
    if [ "$DOMAIN_NAME" != "localhost" ]; then
        echo ""
        echo "🔒 SSL Certificate:"
        echo "  Caddy will automatically obtain SSL certificate for $DOMAIN_NAME"
        echo "  Make sure your domain's DNS points to this server's IP address"
        echo "  Certificate will auto-renew before expiration"
    fi
else
    print_error "❌ Deployment completed with errors"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  Check backend:  sudo journalctl -u nba-backend"
    echo "  Check frontend: sudo journalctl -u nba-frontend" 
    echo "  Check Caddy:    sudo journalctl -u caddy"
    echo "  Test config:    sudo caddy validate --config /etc/caddy/Caddyfile"
    exit 1
fi