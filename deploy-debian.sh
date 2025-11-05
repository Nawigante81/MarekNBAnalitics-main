#!/bin/bash

# NBA Analytics Debian Production Deployment Script
set -e

echo "🏀 NBA Analytics - Debian/Ubuntu Deployment"

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
    print_warning "Running as root. Consider using a non-root user for security."
fi

# Detect Debian/Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    print_status "Detected: $OS $VER"
else
    print_error "Cannot detect OS version"
    exit 1
fi

# Update system packages
print_step "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required system packages
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
    python3-venv \
    libffi-dev \
    libssl-dev \
    pkg-config

# Install Node.js 18.x (official NodeSource repository)
print_step "Installing Node.js 18.x..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Install Python 3.11 if not available
print_step "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
print_status "Python version: $PYTHON_VERSION"

if [[ ! "$PYTHON_VERSION" =~ ^3\.1[1-9] ]]; then
    print_warning "Python 3.11+ recommended. Installing from deadsnakes PPA..."
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get update
    sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
fi

# Install Docker (official Docker repository)
print_step "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    print_warning "Please log out and back in for Docker group membership to take effect"
fi

# Install Docker Compose (standalone)
print_step "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Nginx
print_step "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
fi

# Setup firewall (UFW - default on Debian/Ubuntu)
print_step "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8000/tcp
    sudo ufw allow 5173/tcp
    print_status "Firewall configured"
else
    print_warning "UFW not available. Please configure firewall manually."
fi

# Create application directory
APP_DIR="/var/www/nba-analytics"
print_step "Setting up application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Copy application files if we're not already in the target directory
if [ "$PWD" != "$APP_DIR" ]; then
    print_step "Copying application files..."
    sudo cp -r . $APP_DIR/
    cd $APP_DIR
    sudo chown -R $USER:$USER $APP_DIR
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    print_warning ".env.production not found. Creating from example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env.production
        print_warning "Please edit .env.production with your actual configuration"
    else
        print_error ".env.example not found. Please create .env.production manually."
        exit 1
    fi
fi

# Create logs and ssl directories
mkdir -p logs ssl

# Install application dependencies
print_step "Installing application dependencies..."

# Frontend dependencies
print_status "Installing frontend dependencies..."
npm install

# Backend dependencies
print_status "Installing backend dependencies..."
cd backend
python3 -m pip install --user --upgrade pip
python3 -m pip install --user -r requirements.txt
cd ..

# Build frontend
print_step "Building frontend for production..."
npm run build

# Make scripts executable
chmod +x deploy.sh start.sh stop.sh 2>/dev/null || true

# Setup systemd services option
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
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (using built files served by a simple HTTP server)
sudo tee /etc/systemd/system/nba-frontend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Frontend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
ExecStart=/usr/bin/npx serve -s dist -l 5173
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Setup Nginx configuration
print_step "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/nba-analytics > /dev/null <<EOF
server {
    listen 80;
    server_name localhost $(hostname -I | awk '{print $1}');
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
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
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable nginx site
sudo ln -sf /etc/nginx/sites-available/nba-analytics /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    print_status "Nginx configuration applied"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Choose deployment method
echo ""
echo "🚀 Choose deployment method:"
echo "1) Systemd services (recommended for Debian)"
echo "2) Docker Compose"
echo "3) PM2"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        print_step "Starting systemd services..."
        sudo systemctl enable nba-backend nba-frontend
        sudo systemctl start nba-backend nba-frontend
        
        # Wait for services to start
        sleep 10
        
        # Check service status
        if systemctl is-active --quiet nba-backend && systemctl is-active --quiet nba-frontend; then
            print_status "✅ Services are running!"
            echo ""
            echo "🌐 Frontend: http://$(hostname -I | awk '{print $1}')"
            echo "🚀 Backend: http://$(hostname -I | awk '{print $1}'):8000"
            echo "📊 API Docs: http://$(hostname -I | awk '{print $1}'):8000/docs"
            echo ""
            echo "📋 Management commands:"
            echo "  Status: sudo systemctl status nba-backend nba-frontend"
            echo "  Logs: sudo journalctl -u nba-backend -f"
            echo "  Restart: sudo systemctl restart nba-backend nba-frontend"
        else
            print_error "❌ Services failed to start"
            echo "Check logs: sudo journalctl -u nba-backend -u nba-frontend"
            exit 1
        fi
        ;;
        
    2)
        print_step "Starting Docker Compose..."
        newgrp docker <<EOF
docker-compose down 2>/dev/null || true
docker-compose up --build -d
EOF
        sleep 20
        
        if docker-compose ps | grep -q "Up"; then
            print_status "✅ Docker services are running!"
            echo ""
            echo "🌐 Frontend: http://$(hostname -I | awk '{print $1}')"
            echo "🚀 Backend: http://$(hostname -I | awk '{print $1}'):8000"
        else
            print_error "❌ Docker services failed to start"
            docker-compose logs
            exit 1
        fi
        ;;
        
    3)
        print_step "Installing and configuring PM2..."
        npm install -g pm2
        pm2 delete ecosystem.config.json 2>/dev/null || true
        pm2 start ecosystem.config.json --env production
        pm2 save
        pm2 startup
        
        print_status "✅ PM2 services started!"
        echo ""
        echo "📊 PM2 status: pm2 status"
        echo "📝 PM2 logs: pm2 logs"
        ;;
        
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_status "🎉 Debian deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Configure your domain DNS"
echo "2. Set up SSL certificates with Let's Encrypt:"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d yourdomain.com"
echo "3. Configure environment variables in .env.production"
echo "4. Monitor logs and performance"
echo ""
echo "🔗 Useful commands:"
echo "  Service status: sudo systemctl status nba-backend nba-frontend nginx"
echo "  View logs: sudo journalctl -u nba-backend -f"
echo "  Nginx logs: sudo tail -f /var/log/nginx/access.log"
echo "  Restart all: sudo systemctl restart nba-backend nba-frontend nginx"