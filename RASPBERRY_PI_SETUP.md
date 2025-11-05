# 🥧 Raspberry Pi 4 - Installation Guide

> **Complete setup guide for NBA Analytics on Raspberry Pi 4 (ARM64)**

---

## 🔧 System Requirements

### Hardware Requirements

- **Raspberry Pi 4** (4GB RAM minimum, 8GB recommended)
- **MicroSD Card**: Class 10, 32GB minimum (64GB recommended)
- **Power Supply**: Official Pi 4 USB-C adapter (5V 3A)
- **Network**: Ethernet (recommended) or Wi-Fi

### Software Requirements

- **Raspberry Pi OS**: 64-bit (Bookworm or newer)
- **Docker**: Optional but recommended for easier deployment

---

## 📥 Initial Pi Setup

### 1. Flash Raspberry Pi OS

1. Download **Raspberry Pi Imager**: <https://www.raspberrypi.org/software/>
2. Flash **Raspberry Pi OS (64-bit)** to SD card
3. Enable SSH in imager settings (recommended)

### 2. First Boot Configuration

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y git curl wget htop

# Check architecture (should show aarch64)
uname -m
```

---

## 🐳 Method 1: Docker Installation (Recommended)

### Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo apt install -y docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Deploy NBA Analytics

```bash
# Clone repository
git clone https://github.com/YourUsername/MarekNBAnalitics.git
cd MarekNBAnalitics

# Create environment file
cp .env.example .env

# Edit configuration (use nano or vim)
nano .env

# Add your API keys:
# VITE_SUPABASE_URL=https://your-project.supabase.co
# VITE_SUPABASE_ANON_KEY=your_key_here
# VITE_ODDS_API_KEY=your_odds_key_here

# Deploy with Docker
docker-compose -f docker-compose.pi4.yml up -d

# Check status
docker-compose ps
```

---

## 🔧 Method 2: Native Installation

### Install Node.js (ARM64)

```bash
# Install Node.js 18 LTS (ARM64)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### Install Python Dependencies

```bash
# Install Python development tools
sudo apt install -y python3-dev python3-pip python3-venv
sudo apt install -y build-essential libffi-dev libssl-dev
sudo apt install -y libblas-dev liblapack-dev gfortran

# Clone repository
git clone https://github.com/YourUsername/MarekNBAnalitics.git
cd MarekNBAnalitics

# Run setup script
chmod +x setup.sh
./setup.sh
```

### Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Add your API keys (same as Docker method above)
```

### Start Application

```bash
# Method 1: Automated
./start.sh

# Method 2: Manual (2 terminals)
# Terminal 1 - Backend
cd backend
source venv/bin/activate
python main.py

# Terminal 2 - Frontend
npm run dev
```

---

## 📊 Performance Optimization

### System Optimization

```bash
# Increase GPU memory split for better performance
echo 'gpu_mem=128' | sudo tee -a /boot/config.txt

# Enable memory cgroups
echo 'cgroup_enable=memory cgroup_memory=1' | sudo tee -a /boot/cmdline.txt

# Reboot after changes
sudo reboot
```

### Application Configuration

Create `docker-compose.pi4.yml` for optimized Pi deployment:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.pi4
    container_name: nba-backend-pi4
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - PYTHONPATH=/app
      - TZ=America/Chicago
    env_file:
      - .env
    volumes:
      - ./logs:/app/logs
    mem_limit: 1g
    cpus: 2

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend.pi4
    container_name: nba-frontend-pi4
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
    mem_limit: 512m
    cpus: 1

  redis:
    image: redis:7-alpine
    container_name: nba-redis-pi4
    restart: unless-stopped
    mem_limit: 256m
    command: redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru
```

---

## 🔍 Monitoring & Troubleshooting

### System Monitoring

```bash
# Check system resources
htop

# Monitor temperature (should stay under 80°C)
vcgencmd measure_temp

# Check memory usage
free -h

# Monitor Docker containers
docker stats
```

### Performance Tips

```bash
# Reduce npm memory usage during build
export NODE_OPTIONS="--max_old_space_size=1024"

# Use minimal Python requirements if needed
cd backend
pip install -r requirements-pi4.txt  # Lighter dependencies
```

### Common Issues & Solutions

#### Out of Memory During Build

```bash
# Enable swap file
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE=100 to CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

#### Slow Docker Builds

```bash
# Use multi-stage builds and smaller base images
# Pre-built ARM64 images available on Docker Hub
docker pull your-registry/nba-analytics:pi4-backend
docker pull your-registry/nba-analytics:pi4-frontend
```

#### Network Issues

```bash
# Check network connectivity
ping google.com

# Test API endpoints
curl http://localhost:8000/health
curl http://localhost:8000/api/status
```

---

## 🚀 Production Deployment

### Set up as System Service

```bash
# Create systemd service for auto-start
sudo nano /etc/systemd/system/nba-analytics.service
```

Service file content:

```ini
[Unit]
Description=NBA Analytics Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/pi/MarekNBAnalitics
ExecStart=/usr/bin/docker-compose -f docker-compose.pi4.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.pi4.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

Enable service:

```bash
sudo systemctl enable nba-analytics.service
sudo systemctl start nba-analytics.service

# Check status
sudo systemctl status nba-analytics.service
```

### Access from Network

```bash
# Find Pi IP address
hostname -I

# Access from other devices on network:
# Frontend: http://PI_IP_ADDRESS
# API: http://PI_IP_ADDRESS:8000/docs
```

---

## 📝 Maintenance

### Regular Updates

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd MarekNBAnalitics
docker-compose -f docker-compose.pi4.yml pull
docker-compose -f docker-compose.pi4.yml up -d

# Clean up old images
docker system prune -f
```

### Backup Configuration

```bash
# Backup environment and data
tar -czf nba-analytics-backup-$(date +%Y%m%d).tar.gz .env logs/
```

---

## 🔧 Hardware Recommendations

### Cooling

- **Active cooling recommended** for 24/7 operation
- Consider **Pimoroni Fan SHIM** or **official case fan**

### Storage

- **High-endurance SD cards** (Samsung Endurance, SanDisk High Endurance)
- Consider **USB 3.0 SSD** for better I/O performance

### Networking

- **Ethernet connection preferred** for stable API calls
- **Quality power supply essential** to prevent corruption

---

## 🎯 Expected Performance

### Resource Usage

- **RAM**: 2-3GB total usage
- **CPU**: 20-40% average load
- **Storage**: ~2GB for application + logs
- **Network**: Moderate (API calls every 30 seconds)

### Response Times

- **Frontend load**: 2-5 seconds
- **API responses**: 100-500ms
- **Report generation**: 1-3 seconds

---

## 🆘 Support

For Pi-specific issues:

1. Check system temperature and power supply
2. Verify ARM64 compatibility of all dependencies
3. Monitor resource usage with `htop`
4. Check Docker logs: `docker-compose logs -f`

---

## 🏀 Enjoy NBA Analytics on Your Pi! 🥧
