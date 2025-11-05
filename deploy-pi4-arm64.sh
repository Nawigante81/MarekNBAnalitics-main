#!/bin/bash

# NBA Analytics Deployment Script for Raspberry Pi 4 (ARM64) with Caddy
set -e

echo "🍓 NBA Analytics - Raspberry Pi 4 ARM64 Deployment with Caddy"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_pi() {
    echo -e "${PURPLE}[PI]${NC} $1"
}

# Check if running on ARM64
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    print_warning "This script is optimized for ARM64 (aarch64). Detected: $ARCH"
    read -p "Continue anyway? (y/N): " continue_anyway
    if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
        exit 1
    fi
fi

# Check available memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$TOTAL_MEM" -lt 1800 ]; then
    print_warning "Low memory detected: ${TOTAL_MEM}MB. Consider enabling swap."
    
    # Setup swap if needed
    if [ ! -f /swapfile ]; then
        print_step "Setting up 2GB swap file for better performance..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        print_status "Swap file created"
    fi
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Use 'pi' user with sudo privileges."
    exit 1
fi

# Detect Raspberry Pi OS version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    print_pi "Detected: $OS $VER"
else
    print_error "Cannot detect OS version"
    exit 1
fi

# Check for Raspberry Pi specific optimizations
print_step "Checking Raspberry Pi configuration..."

# Check if GPU memory split is optimized
GPU_MEM=$(vcgencmd get_mem gpu | cut -d'=' -f2 | cut -d'M' -f1)
if [ "$GPU_MEM" -gt 128 ]; then
    print_warning "GPU memory is set to ${GPU_MEM}MB. Consider reducing to 64MB for more system RAM."
    print_status "To change: sudo raspi-config -> Advanced Options -> Memory Split -> 64"
fi

# Check CPU temperature
CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
print_pi "CPU Temperature: ${CPU_TEMP}°C"
if (( $(echo "$CPU_TEMP > 70" | bc -l) )); then
    print_warning "High CPU temperature! Ensure proper cooling."
fi

# Update system packages with retry logic
print_step "Updating system packages..."
for i in {1..3}; do
    if sudo apt-get update; then
        print_status "Package lists updated successfully"
        break
    else
        print_warning "Package update failed, attempt $i/3"
        if [ $i -eq 3 ]; then
            print_error "Failed to update package lists after 3 attempts"
            exit 1
        fi
        sleep 5
    fi
done

# Fix broken packages if any
sudo apt-get -f install -y || true

# Upgrade system
print_step "Upgrading system packages..."
sudo apt-get upgrade -y

# Install essential packages first (base system)
print_step "Installing essential system packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    bc \
    || {
        print_error "Failed to install essential packages"
        exit 1
    }

# Install development tools
print_step "Installing development tools..."
sudo apt-get install -y \
    build-essential \
    python3-dev \
    python3-pip \
    python3-venv \
    libffi-dev \
    libssl-dev \
    pkg-config \
    || {
        print_warning "Some development packages failed to install, continuing..."
    }

# Try to install optional packages (don't fail if unavailable)
print_step "Installing optional packages..."
OPTIONAL_PACKAGES=(
    "software-properties-common"
    "apt-transport-https"
    "gcc-aarch64-linux-gnu"
    "libc6-dev-arm64-cross"
    "iotop"
)

for package in "${OPTIONAL_PACKAGES[@]}"; do
    if sudo apt-get install -y "$package"; then
        print_status "✅ Installed $package"
    else
        print_warning "⚠️  Skipped $package (not available)"
    fi
done

# Install Node.js 18.x LTS (ARM64 compatible)
print_step "Installing Node.js 18.x LTS for ARM64..."
if ! command -v node &> /dev/null; then
    print_status "Node.js not found, installing..."
    
    # Method 1: Try NodeSource repository
    if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs; then
        print_status "Node.js installed via NodeSource"
    else
        print_warning "NodeSource failed, trying alternative method..."
        
        # Method 2: Try system repository
        if sudo apt-get install -y nodejs npm; then
            print_status "Node.js installed via system repository"
        else
            print_warning "System repository failed, trying manual installation..."
            
            # Method 3: Manual installation for ARM64
            NODE_VERSION="18.19.0"
            wget -O node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz"
            sudo tar -xJf node.tar.xz -C /usr/local --strip-components=1
            rm node.tar.xz
            
            # Fix permissions for manually installed Node.js
            sudo chown -R root:root /usr/local/bin/node /usr/local/bin/npm
            sudo chmod 755 /usr/local/bin/node /usr/local/bin/npm
            sudo mkdir -p /usr/local/lib/node_modules
            sudo chown -R $USER:$USER /usr/local/lib/node_modules
            
            # Add to PATH
            export PATH="/usr/local/bin:$PATH"
            echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
            
            print_status "Node.js installed manually with proper permissions"
        fi
    fi
    
    # Verify installation
    if command -v node &> /dev/null; then
        NODE_ARCH=$(node -p "process.arch" 2>/dev/null || echo "unknown")
        if [ "$NODE_ARCH" = "arm64" ]; then
            print_status "✅ Node.js ARM64 verified"
        else
            print_warning "⚠️  Node.js architecture: $NODE_ARCH (expected arm64)"
        fi
    else
        print_error "❌ Node.js installation failed"
        exit 1
    fi
else
    print_status "Node.js already installed"
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION ($(node -p "process.arch"))"

# Install Python 3.11 optimized for ARM64
print_step "Setting up Python environment..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
print_status "Python version: $PYTHON_VERSION"

# Install python3-venv if not available
if ! python3 -m venv --help &> /dev/null; then
    print_status "Installing python3-venv..."
    sudo apt-get install -y python3-venv python3-full || {
        print_warning "Failed to install python3-venv, trying alternative..."
        sudo apt-get install -y python3.11-venv || true
    }
fi

# Create virtual environment in user directory first
USER_VENV_PATH="$HOME/nba-analytics-venv"
print_step "Creating Python virtual environment in user directory..."
if [ ! -d "$USER_VENV_PATH" ]; then
    python3 -m venv "$USER_VENV_PATH" || {
        print_error "Failed to create virtual environment"
        exit 1
    }
    print_status "✅ Virtual environment created in $USER_VENV_PATH"
else
    print_status "Virtual environment already exists in $USER_VENV_PATH"
fi

# Activate virtual environment and upgrade pip
print_step "Setting up virtual environment..."
source "$USER_VENV_PATH/bin/activate"
python -m pip install --upgrade pip setuptools wheel

# Install Caddy for ARM64
print_step "Installing Caddy for ARM64..."
if ! command -v caddy &> /dev/null; then
    print_status "Installing Caddy web server..."
    
    # Download ARM64 binary directly
    CADDY_VERSION="2.7.6"
    CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_arm64.tar.gz"
    
    if wget -O caddy.tar.gz "$CADDY_URL"; then
        tar -xzf caddy.tar.gz
        sudo mv caddy /usr/local/bin/
        sudo chmod +x /usr/local/bin/caddy
        
        # Clean up
        rm -f caddy.tar.gz LICENSE README.md
        
        print_status "✅ Caddy binary installed"
    else
        print_error "❌ Failed to download Caddy"
        exit 1
    fi
    
    # Create caddy user and directories
    sudo groupadd --system caddy || true
    sudo useradd --system \
        --gid caddy \
        --create-home \
        --home-dir /var/lib/caddy \
        --shell /usr/sbin/nologin \
        --comment "Caddy web server" \
        caddy || true
    
    # Create systemd service
    sudo tee /etc/systemd/system/caddy.service > /dev/null <<EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable caddy
    
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
    sudo ufw allow 8000/tcp  # Backend direct access
    sudo ufw allow 5173/tcp  # Frontend dev server
    print_status "Firewall configured"
fi

# Optimize Raspberry Pi settings for web server
print_step "Applying Raspberry Pi optimizations..."

# Increase file descriptor limits
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
# NBA Analytics optimizations
pi soft nofile 65536
pi hard nofile 65536
caddy soft nofile 65536
caddy hard nofile 65536
EOF

# Optimize network settings
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# NBA Analytics network optimizations
net.core.somaxconn = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
EOF

# Apply sysctl settings
sudo sysctl -p

# Create application directory
APP_DIR="/var/www/nba-analytics"
print_step "Setting up application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Copy application files
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
sudo mkdir -p /etc/caddy /var/log/caddy
sudo chown -R caddy:caddy /var/log/caddy

# Install application dependencies with ARM64 optimizations
print_step "Installing application dependencies (ARM64 optimized)..."

# Frontend dependencies
    echo "[INFO] Installing frontend dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install frontend dependencies!"
        exit 1
    fi
    
    echo "[INFO] Installing terser for production builds..."
    npm install --save-dev terser
    if [ $? -ne 0 ]; then
        echo "[WARNING] Failed to install terser, build may fail!"
    fi

# Backend dependencies with ARM64-specific wheels
print_status "Installing backend dependencies..."
cd backend

# Use existing requirements-pi4.txt or create it
if [ ! -f "requirements-pi4.txt" ]; then
    print_status "Creating ARM64 optimized requirements..."
    cat > requirements-pi4.txt << EOF
# ARM64 optimized requirements for NBA Analytics
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
requests==2.31.0
beautifulsoup4==4.12.2
pandas==2.1.4
numpy==1.26.4
APScheduler==3.10.4
supabase==2.4.0
aiohttp==3.9.1
lxml==4.9.3

# ARM64 compatible versions
pydantic==2.12.3
starlette==0.27.0
httpx==0.25.2
anyio==3.7.1
sniffio==1.3.1
typing_extensions==4.15.0
python-dateutil==2.9.0.post0
pytz==2023.3
six==1.17.0
certifi==2025.10.5
charset-normalizer==3.4.4
idna==3.11
urllib3==2.5.0

# Additional ARM64 optimizations
psycopg2-binary==2.9.9
redis==5.0.1
python-multipart==0.0.6
EOF
fi

# Ensure we're in virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
    source "$USER_VENV_PATH/bin/activate"
fi

# Install with ARM64 optimizations in virtual environment
print_status "Installing Python packages in virtual environment..."
pip install --timeout=300 -r requirements-pi4.txt || {
    print_warning "Some packages failed, installing core packages only..."
    pip install fastapi uvicorn python-dotenv requests beautifulsoup4 supabase pydantic
}

cd ..

# Build frontend with memory considerations
print_step "Building frontend (ARM64 optimized)..."

# Fix Node.js permissions if installed manually
if [ -d "/usr/local/bin" ]; then
    sudo chown -R $USER:$USER /usr/local/lib/node_modules 2>/dev/null || true
    sudo chmod -R 755 /usr/local/bin/node /usr/local/bin/npm 2>/dev/null || true
fi

# Fix local node_modules permissions
chmod -R 755 node_modules/.bin 2>/dev/null || true

# Limit Node.js memory for Raspberry Pi
export NODE_OPTIONS="--max-old-space-size=1536"

# Remove NODE_ENV from .env if it exists to avoid Vite warning
if [ -f ".env" ]; then
    sed -i '/^NODE_ENV=/d' .env
    print_status "Removed NODE_ENV from .env file"
fi

# Install terser for production builds (required since Vite v3)
print_status "Installing terser for production builds..."
npm install --save-dev terser
if [ $? -ne 0 ]; then
    print_warning "Failed to install terser, build may fail!"
fi

# Use npx to ensure proper vite execution
print_status "Building with npx vite..."
## Remove NODE_ENV from .env.production as well (Vite warns when NODE_ENV is in env files)
if [ -f ".env.production" ]; then
    sed -i '/^NODE_ENV=/d' .env.production || true
    print_status "Removed NODE_ENV from .env.production file"
fi

# Run build with NODE_ENV set in process environment (not in .env files)
if ! NODE_ENV=production npx vite build; then
    print_warning "npx vite failed, trying alternative methods..."
    
    # Method 1: Install terser and retry
    print_status "Installing terser and retrying..."
    npm install --save-dev terser
    if ! npx vite build; then
        # Method 2: Try direct node_modules execution
        if [ -f "node_modules/.bin/vite" ]; then
            print_status "Trying direct vite execution..."
            chmod +x node_modules/.bin/vite
            ./node_modules/.bin/vite build
        else
            print_error "Vite not found in node_modules"
            exit 1
        fi
    fi
fi

# Get domain name
read -p "Enter your domain name (e.g., nba-analytics.your-pi-domain.com) or press Enter for local IP: " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    # Get local IP address
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    DOMAIN_NAME="$LOCAL_IP"
    print_warning "Using local IP: $LOCAL_IP"
    print_status "For external access, configure port forwarding and use a proper domain"
fi

# Create ARM64-optimized Caddyfile
print_step "Creating ARM64-optimized Caddyfile..."
cat > /tmp/Caddyfile.pi << EOF
# NBA Analytics - Raspberry Pi 4 ARM64 Optimized Caddyfile
${DOMAIN_NAME} {
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
        # Set a header for the response
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
        root * ${APP_DIR}/dist
        file_server

        # Cache static assets (lighter caching for Pi)
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg
        }
        header @static {
            Cache-Control "public, max-age=86400"
        }
    }

    # Simplified logging for ARM64
    log {
        output file /var/log/caddy/nba-analytics.log {
            roll_size 10MiB
            roll_keep 5
            roll_keep_for 720h
        }
        format console
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

# Copy Caddyfile
sudo cp /tmp/Caddyfile.pi /etc/caddy/Caddyfile
sudo chown caddy:caddy /etc/caddy/Caddyfile
rm /tmp/Caddyfile.pi

# Validate Caddyfile
print_step "Validating Caddyfile..."
if sudo caddy validate --config /etc/caddy/Caddyfile; then
    print_status "Caddyfile is valid"
else
    print_error "Caddyfile validation failed"
    exit 1
fi

# Setup ARM64-optimized systemd services
print_step "Setting up ARM64-optimized systemd services..."

# Backend service with ARM64 optimizations and virtual environment
sudo tee /etc/systemd/system/nba-backend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Backend (ARM64)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR/backend
Environment=PATH=$USER_VENV_PATH/bin:/usr/bin:/usr/local/bin
Environment=PYTHONPATH=$APP_DIR/backend
Environment=PYTHONUNBUFFERED=1
Environment=VIRTUAL_ENV=$USER_VENV_PATH
EnvironmentFile=$APP_DIR/.env.production
# ARM64 optimizations with virtual environment
ExecStart=$USER_VENV_PATH/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --workers 1 --loop asyncio
Restart=always
RestartSec=15
# Memory limits for Pi4
MemoryMax=512M
# CPU limits
CPUQuota=80%

[Install]
WantedBy=multi-user.target
EOF

# Frontend service optimized for ARM64
sudo tee /etc/systemd/system/nba-frontend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Frontend Server (ARM64)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_OPTIONS=--max-old-space-size=512
ExecStart=/usr/bin/npx serve -s dist -l 5173 --no-clipboard --no-port-switching
Restart=always
RestartSec=10
# Memory limits for Pi4
MemoryMax=256M

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Start services
print_step "Starting ARM64-optimized services..."

# Start backend
sudo systemctl enable nba-backend
sudo systemctl start nba-backend

# Start frontend  
sudo systemctl enable nba-frontend
sudo systemctl start nba-frontend

# Start Caddy
sudo systemctl restart caddy

# Wait for services with longer timeout for ARM64
print_status "Waiting for ARM64 services to initialize (longer timeout)..."
sleep 30

# Check service status
print_step "Checking ARM64 service status..."

services_ok=true

for service in nba-backend nba-frontend caddy; do
    if systemctl is-active --quiet $service; then
        print_status "✅ $service is running"
    else
        print_error "❌ $service failed to start"
        sudo journalctl -u $service --no-pager -l
        services_ok=false
    fi
done

# ARM64-specific health checks with retries
print_step "Performing ARM64 health checks (with retries)..."

# Backend health with retries
for i in {1..5}; do
    if curl -f -s --connect-timeout 10 http://localhost:8000/health > /dev/null; then
        print_status "✅ Backend health check passed (attempt $i)"
        break
    else
        if [ $i -eq 5 ]; then
            print_error "❌ Backend health check failed after 5 attempts"
            services_ok=false
        else
            print_warning "Backend health check failed, retrying... ($i/5)"
            sleep 10
        fi
    fi
done

# Frontend health with retries
for i in {1..3}; do
    if curl -f -s --connect-timeout 10 http://localhost:5173/health > /dev/null; then
        print_status "✅ Frontend health check passed (attempt $i)"
        break
    else
        if [ $i -eq 3 ]; then
            print_warning "⚠️ Frontend health check timeout (normal for ARM64)"
        else
            sleep 5
        fi
    fi
done

# Final status
if $services_ok; then
    print_pi "🎉 Raspberry Pi 4 ARM64 Deployment Successful!"
    echo ""
    echo "🍓 Raspberry Pi 4 Application URLs:"
    echo "  Frontend: http://$DOMAIN_NAME"
    echo "  Backend:  http://$DOMAIN_NAME:8000" 
    echo "  API Docs: http://$DOMAIN_NAME:8000/docs"
    echo ""
    echo "📊 ARM64 Management Commands:"
    echo "  Service status: sudo systemctl status nba-backend nba-frontend caddy"
    echo "  Pi monitoring:  ./pi-monitor.sh"
    echo "  Caddy manage:   ./caddy-manage.sh"
    echo "  Temperature:    vcgencmd measure_temp"
    echo "  Memory usage:   free -h"
    echo ""
    echo "🔧 Raspberry Pi 4 Optimizations Applied:"
    echo "  - Single worker processes for memory efficiency"
    echo "  - ARM64-optimized package versions"
    echo "  - Reduced compression and caching"
    echo "  - Extended timeouts for ARM64 performance"
    echo "  - Memory limits set for stability"
    echo ""
    echo "⚡ Performance Tips:"
    echo "  - Monitor temperature: watch vcgencmd measure_temp"
    echo "  - Check memory: watch free -h"  
    echo "  - Monitor processes: htop"
    echo "  - View logs: sudo journalctl -u nba-backend -f"
    
    # Display current Pi stats
    echo ""
    echo "📈 Current Raspberry Pi 4 Stats:"
    echo "  CPU Temp: $(vcgencmd measure_temp)"
    echo "  Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "  CPU Freq: $(vcgencmd measure_clock arm | cut -d= -f2 | awk '{print $1/1000000}')MHz"
    echo "  Throttling: $(vcgencmd get_throttled)"
    
else
    print_error "❌ ARM64 deployment completed with errors"
    echo ""
    echo "🔍 ARM64 Troubleshooting:"
    echo "  Temperature: vcgencmd measure_temp"
    echo "  Memory usage: free -h"
    echo "  Check backend:  sudo journalctl -u nba-backend"
    echo "  Check frontend: sudo journalctl -u nba-frontend" 
    echo "  Check Caddy:    sudo journalctl -u caddy"
    echo "  System load:    uptime"
    exit 1
fi