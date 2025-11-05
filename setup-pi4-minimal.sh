#!/bin/bash

# NBA Analytics - Minimal Raspberry Pi 4 Setup
# Use this if the main deployment script has package issues

set -e

echo "🍓 NBA Analytics - Minimal Pi4 Setup"
echo "===================================="

# Colors
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

# Check if Pi4
if [ ! -f /proc/cpuinfo ] || ! grep -q "Raspberry Pi 4" /proc/cpuinfo; then
    print_error "This script is for Raspberry Pi 4 only"
    exit 1
fi

print_status "Raspberry Pi 4 detected ✅"

# Basic system update
print_status "Updating package lists..."
sudo apt-get update || {
    print_warning "Standard update failed, trying to fix..."
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
    sudo apt-get update
}

# Install absolute essentials only
print_status "Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    python3 \
    python3-pip \
    git \
    || {
        print_error "Failed to install essential packages"
        exit 1
    }

# Install Node.js manually (most reliable for ARM64)
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js manually..."
    NODE_VERSION="18.19.0"
    wget -O node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz"
    sudo tar -xJf node.tar.xz -C /usr/local --strip-components=1
    rm node.tar.xz
    
    # Fix permissions
    sudo chown -R root:root /usr/local/bin/node /usr/local/bin/npm
    sudo chmod 755 /usr/local/bin/node /usr/local/bin/npm
    sudo mkdir -p /usr/local/lib/node_modules
    sudo chown -R $USER:$USER /usr/local/lib/node_modules
    
    # Add to PATH
    export PATH="/usr/local/bin:$PATH"
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    
    print_status "Node.js installed ✅"
fi

# Install Caddy manually
if ! command -v caddy &> /dev/null; then
    print_status "Installing Caddy..."
    CADDY_VERSION="2.7.6"
    wget -O caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_arm64.tar.gz"
    tar -xzf caddy.tar.gz
    sudo mv caddy /usr/local/bin/
    sudo chmod +x /usr/local/bin/caddy
    rm -f caddy.tar.gz LICENSE README.md
    
    print_status "Caddy installed ✅"
fi

# Create caddy user and directories
sudo groupadd --system caddy 2>/dev/null || true
sudo useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell /usr/sbin/nologin caddy 2>/dev/null || true

# Setup application directory
APP_DIR="/var/www/nba-analytics"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Copy application files if we're not already in the app directory
if [ "$PWD" != "$APP_DIR" ]; then
    print_status "Copying application files..."
    cp -r . $APP_DIR/
    cd $APP_DIR
fi

# Install frontend dependencies
print_status "Installing frontend dependencies..."
npm install --timeout=300000

# Install terser for production builds (required since Vite v3)
print_status "Installing terser for production builds..."
npm install --save-dev terser --timeout=300000

# Install backend dependencies using virtual environment
print_status "Setting up Python virtual environment..."

# Install python3-venv if needed
sudo apt-get install -y python3-venv python3-full || true

# Create virtual environment in user directory
USER_VENV_PATH="$HOME/nba-analytics-venv"
if [ ! -d "$USER_VENV_PATH" ]; then
    python3 -m venv "$USER_VENV_PATH" || {
        print_error "Failed to create virtual environment"
        exit 1
    }
    print_status "Virtual environment created ✅"
fi

# Activate virtual environment
source "$USER_VENV_PATH/bin/activate"

print_status "Installing backend dependencies in virtual environment..."
cd backend

# Create minimal requirements file
cat > requirements-minimal.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-dotenv==1.0.0
requests==2.31.0
beautifulsoup4==4.12.2
pandas==2.1.4
numpy==1.26.4
supabase==2.4.0
pydantic==2.12.3
EOF

# Install in virtual environment
pip install --timeout=300 -r requirements-minimal.txt || {
    print_warning "Some packages failed, installing core only..."
    pip install fastapi uvicorn python-dotenv requests supabase pydantic
}

cd ..

# Build frontend
print_status "Building frontend..."

# Fix Node.js permissions if needed
if [ -d "/usr/local/bin" ]; then
    sudo chown -R $USER:$USER /usr/local/lib/node_modules 2>/dev/null || true
    sudo chmod -R 755 /usr/local/bin/node /usr/local/bin/npm 2>/dev/null || true
fi

# Fix local permissions
chmod -R 755 node_modules/.bin 2>/dev/null || true

export NODE_OPTIONS="--max-old-space-size=1024"

## Remove NODE_ENV from .env files to avoid Vite warning (NODE_ENV should be set in process env or config)
if [ -f ".env" ]; then
    sed -i '/^NODE_ENV=/d' .env || true
    print_status "Removed NODE_ENV from .env file"
fi
if [ -f ".env.production" ]; then
    sed -i '/^NODE_ENV=/d' .env.production || true
    print_status "Removed NODE_ENV from .env.production file"
fi

# Ensure terser present
print_status "Ensuring terser is installed..."
npm install --save-dev terser --timeout=300000 || print_warning "Failed to install terser"

# Use npx to build with NODE_ENV set in the process environment (not in .env files)
if ! NODE_ENV=production npx vite build; then
    print_warning "npx vite failed, trying alternative..."
    
    # Try installing terser and retry
    print_status "Installing terser and retrying..."
    npm install --save-dev terser --timeout=300000 || true
    if ! NODE_ENV=production npx vite build; then
        if [ -f "node_modules/.bin/vite" ]; then
            chmod +x node_modules/.bin/vite
            ./node_modules/.bin/vite build
        else
            print_error "Vite not found"
            exit 1
        fi
    fi
fi

# Create basic systemd services
print_status "Creating systemd services..."

# Backend service
sudo tee /etc/systemd/system/nba-backend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR/backend
Environment=PYTHONPATH=$APP_DIR/backend
ExecStart=/home/$USER/nba-analytics-venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (simple HTTP server)
sudo tee /etc/systemd/system/nba-frontend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Frontend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m http.server 5173 --directory dist
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Caddy service
sudo tee /etc/systemd/system/caddy.service > /dev/null <<EOF
[Unit]
Description=Caddy
After=network.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# Create basic Caddyfile
sudo mkdir -p /etc/caddy
LOCAL_IP=$(hostname -I | awk '{print $1}')

sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
# NBA Analytics - Basic Pi4 Configuration
$LOCAL_IP, localhost {
    # Health check
    handle /health {
        respond "healthy - Pi4" 200
    }
    
    # API proxy
    handle /api/* {
        reverse_proxy 127.0.0.1:8000
    }
    
    # Frontend
    handle {
        reverse_proxy 127.0.0.1:5173
    }
    
    # Basic logging
    log {
        output file /var/log/caddy/access.log {
            roll_size 10MiB
            roll_keep 3
            roll_keep_for 168h
        }
        format console
    }
}
EOF

sudo mkdir -p /var/log/caddy
sudo chown -R caddy:caddy /etc/caddy /var/log/caddy

# Enable and start services
print_status "Starting services..."
sudo systemctl daemon-reload

sudo systemctl enable nba-backend nba-frontend caddy
sudo systemctl start nba-backend nba-frontend caddy

# Wait for services
sleep 10

# Check status
print_status "Checking service status..."
services_ok=true

for service in nba-backend nba-frontend caddy; do
    if systemctl is-active --quiet $service; then
        print_status "✅ $service is running"
    else
        print_error "❌ $service failed"
        services_ok=false
    fi
done

if $services_ok; then
    echo ""
    print_status "🎉 Minimal setup completed successfully!"
    echo ""
    echo "🍓 Application URLs:"
    echo "  Frontend: http://$LOCAL_IP"
    echo "  Backend:  http://$LOCAL_IP:8000"
    echo ""
    echo "📊 Management commands:"
    echo "  Check status: sudo systemctl status nba-backend nba-frontend caddy"
    echo "  View logs:    sudo journalctl -u nba-backend -f"
    echo "  Restart:      sudo systemctl restart nba-backend nba-frontend caddy"
    echo ""
    echo "🔧 To upgrade to full deployment later:"
    echo "  ./deploy-pi4-arm64.sh"
else
    print_error "Some services failed. Check logs:"
    echo "  sudo journalctl -u nba-backend"
    echo "  sudo journalctl -u nba-frontend"
    echo "  sudo journalctl -u caddy"
fi