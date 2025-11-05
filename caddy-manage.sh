#!/bin/bash

# Caddy Management Script for NBA Analytics
set -e

echo "🏀 NBA Analytics - Caddy Management"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Caddy is installed
if ! command -v caddy &> /dev/null; then
    print_error "Caddy is not installed. Please run deploy-caddy.sh first."
    exit 1
fi

# Main menu
show_menu() {
    echo ""
    echo "🔧 Caddy Management Options:"
    echo "1. Status check"
    echo "2. Restart services"
    echo "3. Reload Caddy config"
    echo "4. View logs"
    echo "5. Test configuration"
    echo "6. Update SSL certificate"
    echo "7. Show current config"
    echo "8. Performance stats"
    echo "9. Backup configuration"
    echo "10. Exit"
    echo ""
}

# Status check
status_check() {
    print_step "Checking service status..."
    
    echo ""
    echo "📊 Service Status:"
    
    if systemctl is-active --quiet caddy; then
        print_status "✅ Caddy is running"
    else
        print_error "❌ Caddy is not running"
    fi
    
    if systemctl is-active --quiet nba-backend; then
        print_status "✅ NBA Backend is running"
    else
        print_error "❌ NBA Backend is not running"
    fi
    
    if systemctl is-active --quiet nba-frontend; then
        print_status "✅ NBA Frontend is running"
    else
        print_error "❌ NBA Frontend is not running"
    fi
    
    echo ""
    echo "🌐 Health Checks:"
    
    if curl -f -s http://localhost/health > /dev/null; then
        print_status "✅ Frontend accessible"
    else
        print_error "❌ Frontend not accessible"
    fi
    
    if curl -f -s http://localhost:8000/health > /dev/null; then
        print_status "✅ Backend accessible"
    else
        print_error "❌ Backend not accessible"
    fi
    
    echo ""
    echo "🔌 Port Status:"
    netstat -tuln | grep -E ":80|:443|:8000|:5173" | while read line; do
        port=$(echo $line | awk '{print $4}' | cut -d: -f2)
        print_status "Port $port is listening"
    done
}

# Restart services
restart_services() {
    print_step "Restarting all services..."
    
    sudo systemctl restart nba-backend
    print_status "Backend restarted"
    
    sudo systemctl restart nba-frontend  
    print_status "Frontend restarted"
    
    sudo systemctl restart caddy
    print_status "Caddy restarted"
    
    sleep 5
    print_status "All services restarted successfully"
}

# Reload Caddy config
reload_config() {
    print_step "Reloading Caddy configuration..."
    
    # Test config first
    if sudo caddy validate --config /etc/caddy/Caddyfile; then
        print_status "Configuration is valid"
        sudo systemctl reload caddy
        print_status "Caddy configuration reloaded"
    else
        print_error "Configuration validation failed"
        return 1
    fi
}

# View logs
view_logs() {
    echo ""
    echo "📝 Log Options:"
    echo "1. Caddy logs"
    echo "2. Backend logs"
    echo "3. Frontend logs"
    echo "4. All logs (live)"
    echo "5. Error logs only"
    echo ""
    
    read -p "Choose log type (1-5): " log_choice
    
    case $log_choice in
        1)
            print_step "Showing Caddy logs (Press Ctrl+C to exit)..."
            sudo journalctl -u caddy -f
            ;;
        2)
            print_step "Showing Backend logs (Press Ctrl+C to exit)..."
            sudo journalctl -u nba-backend -f
            ;;
        3)
            print_step "Showing Frontend logs (Press Ctrl+C to exit)..."
            sudo journalctl -u nba-frontend -f
            ;;
        4)
            print_step "Showing all logs (Press Ctrl+C to exit)..."
            sudo journalctl -u caddy -u nba-backend -u nba-frontend -f
            ;;
        5)
            print_step "Showing error logs..."
            echo "Caddy errors:"
            sudo journalctl -u caddy -p err --since "1 hour ago" --no-pager
            echo ""
            echo "Backend errors:"
            sudo journalctl -u nba-backend -p err --since "1 hour ago" --no-pager
            echo ""
            echo "Frontend errors:"
            sudo journalctl -u nba-frontend -p err --since "1 hour ago" --no-pager
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Test configuration
test_config() {
    print_step "Testing Caddy configuration..."
    
    if sudo caddy validate --config /etc/caddy/Caddyfile; then
        print_status "✅ Configuration is valid"
        
        # Additional tests
        print_step "Testing HTTP connectivity..."
        
        if curl -I http://localhost 2>/dev/null | grep -q "200 OK"; then
            print_status "✅ HTTP connectivity OK"
        else
            print_warning "⚠️ HTTP connectivity issue"
        fi
        
        # Check HTTPS if not localhost
        if ! grep -q "localhost" /etc/caddy/Caddyfile; then
            domain=$(grep -E "^[a-zA-Z0-9.-]+\s*{" /etc/caddy/Caddyfile | head -1 | awk '{print $1}')
            if [ ! -z "$domain" ]; then
                print_step "Testing HTTPS for $domain..."
                if curl -I https://$domain 2>/dev/null | grep -q "200 OK"; then
                    print_status "✅ HTTPS connectivity OK"
                else
                    print_warning "⚠️ HTTPS connectivity issue"
                fi
            fi
        fi
    else
        print_error "❌ Configuration validation failed"
        return 1
    fi
}

# Update SSL certificate
update_ssl() {
    print_step "Checking SSL certificate status..."
    
    # Get domain from Caddyfile
    domain=$(grep -E "^[a-zA-Z0-9.-]+\s*{" /etc/caddy/Caddyfile | head -1 | awk '{print $1}')
    
    if [ -z "$domain" ] || [ "$domain" = "localhost" ]; then
        print_warning "No domain configured for SSL"
        return 0
    fi
    
    print_status "Domain: $domain"
    
    # Caddy handles SSL automatically, but we can force a reload
    print_step "Forcing SSL certificate update..."
    sudo systemctl reload caddy
    
    sleep 10
    
    # Test SSL
    if curl -I https://$domain 2>/dev/null | grep -q "200 OK"; then
        print_status "✅ SSL certificate is working"
    else
        print_error "❌ SSL certificate issue"
    fi
}

# Show current config
show_config() {
    print_step "Current Caddy configuration:"
    echo ""
    sudo cat /etc/caddy/Caddyfile
    echo ""
    
    print_step "Configuration file location: /etc/caddy/Caddyfile"
    print_step "To edit: sudo nano /etc/caddy/Caddyfile"
    print_step "After editing, reload with option 3"
}

# Performance stats
performance_stats() {
    print_step "Performance Statistics:"
    echo ""
    
    # System resources
    echo "💾 Memory Usage:"
    free -h | grep -E "Mem|Swap"
    echo ""
    
    echo "🔥 CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 $4}'
    echo ""
    
    # Service memory usage
    echo "📊 Service Memory Usage:"
    for service in caddy nba-backend nba-frontend; do
        if systemctl is-active --quiet $service; then
            memory=$(systemctl show $service --property=MemoryCurrent --value)
            if [ "$memory" != "[not set]" ] && [ "$memory" != "0" ]; then
                memory_mb=$((memory / 1024 / 1024))
                echo "$service: ${memory_mb}MB"
            fi
        fi
    done
    echo ""
    
    # Connection stats
    echo "🌐 Connection Statistics:"
    echo "Active connections: $(netstat -an | grep :80 | wc -l)"
    echo "HTTPS connections: $(netstat -an | grep :443 | wc -l)"
    echo ""
    
    # Disk usage
    echo "💿 Disk Usage:"
    df -h / | tail -1
    echo "Log files: $(sudo du -sh /var/log/caddy 2>/dev/null || echo "N/A")"
}

# Backup configuration
backup_config() {
    BACKUP_DIR="/var/backups/nba-analytics"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    print_step "Creating configuration backup..."
    
    sudo mkdir -p $BACKUP_DIR
    
    # Backup Caddyfile
    sudo cp /etc/caddy/Caddyfile "$BACKUP_DIR/Caddyfile_$TIMESTAMP"
    
    # Backup systemd services
    sudo cp /etc/systemd/system/nba-*.service "$BACKUP_DIR/" 2>/dev/null || true
    
    # Backup app config
    if [ -f "/var/www/nba-analytics/.env.production" ]; then
        sudo cp /var/www/nba-analytics/.env.production "$BACKUP_DIR/env.production_$TIMESTAMP"
    fi
    
    print_status "✅ Backup created in $BACKUP_DIR"
    sudo ls -la $BACKUP_DIR
}

# Main loop
while true; do
    show_menu
    read -p "Choose an option (1-10): " choice
    
    case $choice in
        1) status_check ;;
        2) restart_services ;;
        3) reload_config ;;
        4) view_logs ;;
        5) test_config ;;
        6) update_ssl ;;
        7) show_config ;;
        8) performance_stats ;;
        9) backup_config ;;
        10) 
            print_status "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-10."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done