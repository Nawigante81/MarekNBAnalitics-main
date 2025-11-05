#!/bin/bash

# NBA Analytics Monitoring Script for Debian/Ubuntu
# Run this script to check system health and application status

echo "🏀 NBA Analytics - System Monitor"
echo "=================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# System Information
echo ""
echo "📊 System Information:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | grep -ohe 'load average[s:][: ].*' | awk '{ print $3 $4 $5 }')"

# Memory and Disk Usage
echo ""
echo "💾 Resource Usage:"
free -h | grep -E "Mem|Swap"
echo "Disk: $(df -h / | awk 'NR==2{printf "%s/%s (%s used)", $3,$2,$5}')"

# Check Services Status
echo ""
echo "🔧 Service Status:"

# Check systemd services
if systemctl is-active --quiet nba-backend; then
    print_ok "NBA Backend (systemd)"
else
    print_error "NBA Backend (systemd) - not running"
fi

if systemctl is-active --quiet nba-frontend; then
    print_ok "NBA Frontend (systemd)"
else
    print_error "NBA Frontend (systemd) - not running"
fi

if systemctl is-active --quiet nginx; then
    print_ok "Nginx"
else
    print_error "Nginx - not running"
fi

# Check Docker services (if running)
if command -v docker-compose &> /dev/null; then
    if docker-compose ps | grep -q "Up"; then
        print_ok "Docker Compose services"
    else
        print_warning "Docker Compose - no services running"
    fi
fi

# Check PM2 services (if running)
if command -v pm2 &> /dev/null; then
    PM2_STATUS=$(pm2 jlist 2>/dev/null)
    if echo "$PM2_STATUS" | grep -q '"status":"online"'; then
        print_ok "PM2 services"
    else
        print_warning "PM2 - no services running"
    fi
fi

# Port Check
echo ""
echo "🌐 Port Status:"
for port in 80 443 8000 5173; do
    if netstat -tuln | grep -q ":$port "; then
        print_ok "Port $port is open"
    else
        print_error "Port $port is not listening"
    fi
done

# Health Checks
echo ""
echo "❤️ Health Checks:"

# Frontend health check
if curl -f -s http://localhost/health > /dev/null 2>&1; then
    print_ok "Frontend health check"
else
    print_error "Frontend health check failed"
fi

# Backend health check
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    print_ok "Backend health check"
else
    print_error "Backend health check failed"
fi

# SSL Certificate Check (if exists)
if [ -f /etc/letsencrypt/live/*/fullchain.pem ]; then
    CERT_FILE=$(ls /etc/letsencrypt/live/*/fullchain.pem | head -1)
    DOMAIN=$(basename $(dirname $CERT_FILE))
    EXPIRY=$(openssl x509 -enddate -noout -in $CERT_FILE | cut -d= -f2)
    EXPIRY_DATE=$(date -d "$EXPIRY" +%s)
    CURRENT_DATE=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))
    
    if [ $DAYS_LEFT -gt 30 ]; then
        print_ok "SSL Certificate ($DOMAIN) - $DAYS_LEFT days left"
    elif [ $DAYS_LEFT -gt 7 ]; then
        print_warning "SSL Certificate ($DOMAIN) - $DAYS_LEFT days left"
    else
        print_error "SSL Certificate ($DOMAIN) - expires in $DAYS_LEFT days!"
    fi
fi

# Log File Sizes
echo ""
echo "📝 Log Files:"
if [ -d "./logs" ]; then
    du -sh logs/* 2>/dev/null | sort -h || echo "No log files found"
fi

# Recent Errors
echo ""
echo "🚨 Recent Errors (last 10):"
echo "Backend errors:"
sudo journalctl -u nba-backend --since "1 hour ago" -p err --no-pager -n 5 2>/dev/null || echo "No recent backend errors"

echo "Frontend errors:"
sudo journalctl -u nba-frontend --since "1 hour ago" -p err --no-pager -n 5 2>/dev/null || echo "No recent frontend errors"

echo "Nginx errors:"
sudo tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "No recent nginx errors"

# Performance Stats
echo ""
echo "⚡ Performance:"
echo "Active connections: $(netstat -an | grep :80 | wc -l)"
echo "Process count: $(ps aux | wc -l)"
echo "CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')"

# Quick Actions Menu
echo ""
echo "🔧 Quick Actions:"
echo "1. Restart all services"
echo "2. View live logs"
echo "3. Check disk space"
echo "4. Update SSL certificate"
echo "5. Exit"

read -p "Choose an action (1-5): " choice

case $choice in
    1)
        echo "Restarting services..."
        sudo systemctl restart nba-backend nba-frontend nginx
        print_ok "Services restarted"
        ;;
    2)
        echo "Showing live logs (Press Ctrl+C to exit):"
        sudo journalctl -u nba-backend -u nba-frontend -f
        ;;
    3)
        echo "Disk usage by directory:"
        sudo du -sh /* 2>/dev/null | sort -h | tail -10
        ;;
    4)
        echo "Updating SSL certificate..."
        sudo certbot renew
        ;;
    5)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac