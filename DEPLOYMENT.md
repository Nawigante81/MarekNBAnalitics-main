# 🏀 NBA Analytics - Production Deployment Guide

This guide covers deploying the NBA Analytics & Betting System to production.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker & Docker Compose (recommended)
- SSL certificates (for HTTPS)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd boltAOONEW

# Copy and configure environment
cp .env.example .env.production
# Edit .env.production with your actual values
```

### 2. Configure Environment Variables
Edit `.env.production`:
```bash
# Required
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
ODDS_API_KEY=your_odds_api_key

# Optional but recommended
SECRET_KEY=your_secret_key
SENTRY_DSN=your_sentry_dsn
```

### 3. Deploy (Choose One Method)

#### Option A: Docker Compose (Recommended)
```bash
chmod +x deploy.sh start.sh stop.sh
./deploy.sh
# Choose option 1 for Docker
```

#### Option B: PM2 Process Manager
```bash
npm install -g pm2
./deploy.sh
# Choose option 2 for PM2
```

#### Option C: Raspberry Pi 4 ARM64 (Special)
```bash
# For Pi4 with ARM64 architecture
chmod +x deploy-pi4-arm64.sh
./deploy-pi4-arm64.sh
```

#### Option C: Quick Start
```bash
chmod +x start.sh
./start.sh
```

## 🏗️ Deployment Methods

### 🐳 Docker Deployment
- **Best for**: Production servers, scalability
- **Includes**: Auto-restart, health checks, load balancing
- **URLs**: Frontend: http://localhost, Backend: http://localhost:8000

### ⚙️ PM2 Deployment  
- **Best for**: VPS, shared hosting
- **Features**: Process monitoring, auto-restart, logging
- **Commands**: `pm2 status`, `pm2 logs`, `pm2 monit`

### 🔧 Systemd Services
- **Best for**: Linux servers, system integration
- **Features**: System-level service management
- **Commands**: `systemctl status nba-backend`

## 📊 Monitoring & Health Checks

### Health Endpoints
- Frontend: `http://localhost/health`
- Backend: `http://localhost:8000/health`
- API Docs: `http://localhost:8000/docs`

### Monitoring Commands
```bash
# Docker
docker-compose ps
docker-compose logs -f

# PM2
pm2 status
pm2 logs
pm2 monit

# System Resources
htop
df -h
```

## 🔒 Security Setup

### 1. SSL Certificates
```bash
# Create SSL directory
mkdir -p ssl

# Add your certificates
ssl/fullchain.pem
ssl/privkey.pem
```

### 2. Firewall Configuration (Debian/Ubuntu)
```bash
# UFW Firewall (default on Debian/Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw --force enable

# Check firewall status
sudo ufw status verbose
```

### 3. Reverse Proxy Setup

#### Option A: Caddy (Recommended - Auto SSL)
```bash
# Run Caddy deployment script
chmod +x deploy-caddy.sh caddy-manage.sh
./deploy-caddy.sh

# Management
./caddy-manage.sh
```

#### Option B: Nginx (Manual SSL)  
```bash
# Copy production nginx config
sudo cp nginx-production.conf /etc/nginx/sites-available/nba-analytics
sudo ln -s /etc/nginx/sites-available/nba-analytics /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🚀 Performance Optimization

### Frontend Optimizations
- ✅ Code splitting with manual chunks
- ✅ Minification with Terser
- ✅ Asset compression (Gzip)
- ✅ Caching headers
- ✅ CDN ready

### Backend Optimizations
- ✅ Multi-worker Uvicorn
- ✅ Connection pooling
- ✅ Redis caching (optional)
- ✅ Request rate limiting
- ✅ Health monitoring

## 📝 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check ports
sudo lsof -i :8000
sudo lsof -i :5173

# Check logs
docker-compose logs backend
pm2 logs nba-backend
```

#### Database Connection Issues
```bash
# Test Supabase connection
curl -X GET "https://your-project.supabase.co/rest/v1/" \
  -H "apikey: your-anon-key"
```

#### SSL Certificate Issues
```bash
# Test SSL
openssl s_client -connect yourdomain.com:443

# Check nginx config
sudo nginx -t
```

### Log Locations
- Docker: `docker-compose logs`
- PM2: `~/.pm2/logs/`
- Application: `./logs/`
- Nginx: `/var/log/nginx/`

## 🔄 Updates & Maintenance

### Update Application
```bash
git pull origin main
./stop.sh
./deploy.sh
```

### Backup Data
```bash
# Backup logs
tar -czf backup-$(date +%Y%m%d).tar.gz logs/

# Backup config
cp .env.production .env.production.backup
```

### Scale Services
```bash
# Docker - increase replicas
docker-compose up --scale backend=3

# PM2 - increase instances
pm2 scale nba-backend 3
```

## 📞 Support

### Service Status
- Frontend: http://localhost/health
- Backend: http://localhost:8000/health
- Monitoring: PM2 Monit, Docker stats

### Performance Metrics
- Response times: Nginx access logs
- Error rates: Application logs
- Resource usage: `htop`, `docker stats`

For issues, check logs first, then consult this guide.