# 🛠️ Raspberry Pi 4 Troubleshooting Guide

## Common Package Manager Issues

### "Unable to locate package software-properties-common"

This error occurs when package repositories are not properly configured or outdated.

#### Solution 1: Update Package Lists
```bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
```

#### Solution 2: Fix Repository Sources
```bash
# Check current sources
cat /etc/apt/sources.list

# Add missing repositories for Raspberry Pi OS
echo "deb http://raspbian.raspberrypi.org/raspbian/ bullseye main contrib non-free rpi" | sudo tee -a /etc/apt/sources.list
echo "deb http://archive.raspberrypi.org/debian/ bullseye main" | sudo tee -a /etc/apt/sources.list.d/raspi.list

# Import GPG keys
wget -O - https://archive.raspberrypi.org/debian/raspberrypi.gpg.key | sudo apt-key add -
sudo apt-get update
```

#### Solution 3: Use Minimal Setup
If package issues persist, use the minimal installer:
```bash
chmod +x setup-pi4-minimal.sh
./setup-pi4-minimal.sh
```

## System Preparation

### Before Running Any Deployment Script
```bash
# 1. Check system compatibility
chmod +x check-pi4-system.sh
./check-pi4-system.sh

# 2. Update system
sudo apt-get update && sudo apt-get upgrade -y

# 3. Fix any broken packages
sudo apt-get -f install
```

### Repository Configuration for Different OS Versions

#### Raspberry Pi OS Bullseye (11)
```bash
# /etc/apt/sources.list
deb http://raspbian.raspberrypi.org/raspbian/ bullseye main contrib non-free rpi
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb http://raspbian.raspberrypi.org/raspbian/ bullseye-updates main contrib non-free rpi

# /etc/apt/sources.list.d/raspi.list
deb http://archive.raspberrypi.org/debian/ bullseye main
```

#### Raspberry Pi OS Bookworm (12)
```bash
# /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware

# /etc/apt/sources.list.d/raspi.list
deb http://archive.raspberrypi.org/debian/ bookworm main
```

## Manual Package Installation

### Essential Packages (if automatic fails)
```bash
# Download and install manually
wget http://ftp.debian.org/debian/pool/main/s/software-properties-common/software-properties-common_0.99.30-4_all.deb
sudo dpkg -i software-properties-common_0.99.30-4_all.deb
sudo apt-get -f install

# Alternative: Install from different source
sudo apt-get install python3-software-properties
```

### Node.js Manual Installation (Most Reliable)
```bash
# Download ARM64 binary directly
NODE_VERSION="18.19.0"
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz
tar -xJf node-v${NODE_VERSION}-linux-arm64.tar.xz
sudo cp -r node-v${NODE_VERSION}-linux-arm64/* /usr/local/
rm -rf node-v${NODE_VERSION}-linux-arm64*

# Fix permissions for proper execution
sudo chown -R root:root /usr/local/bin/node /usr/local/bin/npm
sudo chmod 755 /usr/local/bin/node /usr/local/bin/npm
sudo mkdir -p /usr/local/lib/node_modules
sudo chown -R $USER:$USER /usr/local/lib/node_modules

# Verify installation
node --version
npm --version
```

### Fix "vite: Permission denied" Error
```bash
# Fix Node.js permissions
sudo chown -R $USER:$USER /usr/local/lib/node_modules
sudo chmod -R 755 /usr/local/bin/node /usr/local/bin/npm

# Fix local node_modules permissions
chmod -R 755 node_modules/.bin

# Use npx instead of direct execution
npx vite build

# OR run vite directly if npx fails
./node_modules/.bin/vite build
```

### Python Packages for ARM64

#### Virtual Environment Usage (Recommended)
Scripts now create venv in user directory to avoid permission issues:

```bash
# Virtual environment location
~/nba-analytics-venv/

# Activate manually if needed
source ~/nba-analytics-venv/bin/activate

# Install packages in venv
pip install --prefer-binary --timeout=300 fastapi uvicorn

# Use specific ARM64 requirements
pip install -r backend/requirements-pi4.txt

# Deactivate when done
deactivate
```

#### Legacy System-wide Installation (Not Recommended)
```bash
# Only if virtual environment fails
pip3 install --user --prefer-binary --timeout=300 fastapi uvicorn

# If compilation fails, install build dependencies
sudo apt-get install python3-dev build-essential libffi-dev libssl-dev
```

## Network Issues

### DNS Resolution Problems
```bash
# Check DNS
nslookup google.com

# Fix DNS if needed
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Permanent DNS fix
sudo nano /etc/dhcpcd.conf
# Add: static domain_name_servers=8.8.8.8 1.1.1.1
```

### Package Download Timeouts
```bash
# Increase timeout
echo 'Acquire::http::Timeout "300";' | sudo tee /etc/apt/apt.conf.d/99timeout
echo 'Acquire::ftp::Timeout "300";' | sudo tee -a /etc/apt/apt.conf.d/99timeout

# Use different mirror
sudo sed -i 's|http://raspbian.raspberrypi.org|http://mirror.ox.ac.uk/sites/archive.raspberrypi.org|g' /etc/apt/sources.list
```

## Hardware Issues

### High Temperature (>80°C)
```bash
# Check temperature
vcgencmd measure_temp

# Add cooling solutions:
# - Install heatsink
# - Add cooling fan
# - Improve case ventilation

# Reduce CPU usage temporarily
echo 'arm_freq=1200' | sudo tee -a /boot/config.txt
sudo reboot
```

### Memory Issues (OOM Killer)
```bash
# Add swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Reduce GPU memory
echo 'gpu_mem=64' | sudo tee -a /boot/config.txt
sudo reboot
```

### SD Card Issues
```bash
# Check SD card health
sudo fsck -f /dev/mmcblk0p2

# Check for bad sectors
sudo badblocks -v /dev/mmcblk0p2

# Optimize for SD card
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
```

## Service Issues

### Services Won't Start
```bash
# Check service status
sudo systemctl status nba-backend

# View detailed logs
sudo journalctl -u nba-backend --no-pager -l

# Check system resources
free -h
df -h
uptime

# Restart with debug
sudo systemctl stop nba-backend
sudo -u pi /home/pi/.local/bin/uvicorn main:app --host 127.0.0.1 --port 8000
```

### Port Already in Use
```bash
# Find process using port
sudo netstat -tulpn | grep :8000
sudo lsof -i :8000

# Kill process if needed
sudo kill -9 <PID>

# Check for multiple instances
ps aux | grep uvicorn
ps aux | grep caddy
```

## Deployment Strategies

### Strategy 1: Full Deployment (Recommended)
```bash
./check-pi4-system.sh  # Check compatibility first
./deploy-pi4-arm64.sh  # Full deployment with optimizations
```

### Strategy 2: Minimal Deployment (Fallback)
```bash
./setup-pi4-minimal.sh  # Minimal setup with fewer dependencies
```

### Strategy 3: Docker Deployment
```bash
# Requires Docker to be installed first
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi
newgrp docker

# Then use Pi4 Docker Compose
docker-compose -f docker-compose.pi4.yml up -d
```

### Strategy 4: Manual Step-by-Step
```bash
# 1. Install Node.js manually
wget https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-arm64.tar.xz
sudo tar -xJf node-v18.19.0-linux-arm64.tar.xz -C /usr/local --strip-components=1

# 2. Install Python packages
pip3 install --user fastapi uvicorn python-dotenv requests

# 3. Install Caddy
wget https://github.com/caddyserver/caddy/releases/download/v2.7.6/caddy_2.7.6_linux_arm64.tar.gz
tar -xzf caddy_2.7.6_linux_arm64.tar.gz
sudo mv caddy /usr/local/bin/

# 4. Build and deploy manually
npm install && npm run build
# Configure services manually
```

## Emergency Recovery

### System Won't Boot
```bash
# Boot from another SD card
# Mount original SD card
sudo mount /dev/mmcblk0p2 /mnt

# Check and fix filesystem
sudo fsck -y /dev/mmcblk0p2

# Remove problematic services
sudo rm /mnt/etc/systemd/system/nba-*
```

### Complete Reset
```bash
# Stop all services
sudo systemctl stop nba-backend nba-frontend caddy

# Remove installed files
sudo rm -rf /var/www/nba-analytics
sudo rm /etc/systemd/system/nba-*
sudo rm /etc/systemd/system/caddy.service
sudo rm -rf /etc/caddy

# Clean up
sudo systemctl daemon-reload
sudo apt-get autoremove -y
```

## Getting Help

### Collect System Information
```bash
# Create debug report
./check-pi4-system.sh > pi4-debug-report.txt
dmesg | tail -50 >> pi4-debug-report.txt
sudo journalctl --since="1 hour ago" >> pi4-debug-report.txt
```

### Common Log Locations
```bash
# System logs
sudo journalctl -u nba-backend
sudo journalctl -u nba-frontend  
sudo journalctl -u caddy

# Application logs
tail -f /var/www/nba-analytics/backend/logs/*.log
tail -f /var/log/caddy/*.log

# System logs
dmesg | grep -i error
tail -f /var/log/syslog
```

Remember: The Raspberry Pi 4 is a capable but resource-limited device. Always monitor temperature, memory usage, and storage space during deployment and operation.