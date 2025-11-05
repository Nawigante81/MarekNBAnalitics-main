#!/bin/bash

# NBA Analytics - Quick Start Script for Raspberry Pi 4 ARM64
set -e

echo "🍓 NBA Analytics - Raspberry Pi 4 Quick Start"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running on Raspberry Pi 4
check_pi4() {
    if [ ! -f /proc/cpuinfo ] || ! grep -q "Raspberry Pi 4" /proc/cpuinfo; then
        print_error "This script is designed for Raspberry Pi 4"
        exit 1
    fi
    
    ARCH=$(uname -m)
    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        print_error "ARM64 architecture required. Detected: $ARCH"
        exit 1
    fi
    
    print_status "Raspberry Pi 4 ARM64 detected ✅"
}

# Check if already deployed
check_existing_deployment() {
    if systemctl is-active --quiet nba-backend && \
       systemctl is-active --quiet nba-frontend && \
       systemctl is-active --quiet caddy; then
        print_status "NBA Analytics is already running!"
        echo ""
        echo "🍓 Application URLs:"
        echo "  Frontend: http://$(hostname -I | awk '{print $1}')"
        echo "  Backend:  http://$(hostname -I | awk '{print $1}'):8000"
        echo "  API Docs: http://$(hostname -I | awk '{print $1}'):8000/docs"
        echo ""
        echo "Management commands:"
        echo "  Monitor: ./pi-monitor.sh"
        echo "  Manage:  ./caddy-manage.sh"
        echo ""
        read -p "Restart services? (y/N): " restart
        if [[ "$restart" == "y" || "$restart" == "Y" ]]; then
            restart_services
        fi
        exit 0
    fi
}

# Quick restart services
restart_services() {
    print_step "Restarting services..."
    
    services=("nba-backend" "nba-frontend" "caddy")
    for service in "${services[@]}"; do
        print_status "Restarting $service..."
        sudo systemctl restart $service
        sleep 2
    done
    
    print_status "All services restarted"
    show_status
}

# Show current status
show_status() {
    print_step "Checking service status..."
    
    services=("nba-backend" "nba-frontend" "caddy")
    all_running=true
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            print_status "✅ $service is running"
        else
            print_error "❌ $service is not running"
            all_running=false
        fi
    done
    
    if $all_running; then
        echo ""
        print_status "🎉 All services are running!"
        echo ""
        echo "🍓 Pi4 Application URLs:"
        LOCAL_IP=$(hostname -I | awk '{print $1}')
        echo "  Frontend: http://$LOCAL_IP"
        echo "  Backend:  http://$LOCAL_IP:8000"
        echo "  API Docs: http://$LOCAL_IP:8000/docs"
        echo ""
        
        # Show Pi4 stats
        if command -v vcgencmd &> /dev/null; then
            CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
            MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
            echo "📊 Pi4 Status:"
            echo "  Temperature: $CPU_TEMP"
            echo "  Memory: ${MEM_USAGE}%"
            echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"
        fi
    else
        print_error "Some services are not running. Run full deployment script:"
        echo "  ./deploy-pi4-arm64.sh"
    fi
}

# Interactive menu
show_menu() {
    echo ""
    echo "🍓 NBA Analytics Pi4 Quick Actions:"
    echo "1) Show status"
    echo "2) Restart services"
    echo "3) Open monitoring"
    echo "4) View logs"
    echo "5) Full deployment"
    echo "6) System info"
    echo "0) Exit"
    echo ""
    read -p "Choose action [0-6]: " choice
}

# View logs
view_logs() {
    echo "Select service to view logs:"
    echo "1) Backend (nba-backend)"
    echo "2) Frontend (nba-frontend)"
    echo "3) Caddy web server"
    echo "4) All services"
    echo ""
    read -p "Choose [1-4]: " log_choice
    
    case $log_choice in
        1)
            print_status "Backend logs (press Ctrl+C to exit):"
            sudo journalctl -u nba-backend -f
            ;;
        2)
            print_status "Frontend logs (press Ctrl+C to exit):"
            sudo journalctl -u nba-frontend -f
            ;;
        3)
            print_status "Caddy logs (press Ctrl+C to exit):"
            sudo journalctl -u caddy -f
            ;;
        4)
            print_status "All service logs (press Ctrl+C to exit):"
            sudo journalctl -u nba-backend -u nba-frontend -u caddy -f
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# System information
show_system_info() {
    print_step "Raspberry Pi 4 System Information"
    echo ""
    
    if [ -f /proc/cpuinfo ]; then
        MODEL=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | xargs)
        echo "🍓 Model: $MODEL"
        
        SERIAL=$(grep "Serial" /proc/cpuinfo | cut -d':' -f2 | xargs)
        echo "📋 Serial: $SERIAL"
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "💿 OS: $PRETTY_NAME"
    fi
    
    echo "🏗️  Architecture: $(uname -m)"
    echo "🧠 Kernel: $(uname -r)"
    echo "⏰ Uptime: $(uptime -p)"
    
    if command -v vcgencmd &> /dev/null; then
        echo ""
        echo "🌡️  Hardware Status:"
        CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
        echo "   Temperature: $CPU_TEMP"
        
        CPU_FREQ=$(vcgencmd measure_clock arm | cut -d= -f2)
        CPU_FREQ_MHZ=$(echo "scale=0; $CPU_FREQ/1000000" | bc 2>/dev/null || echo "N/A")
        echo "   CPU Frequency: ${CPU_FREQ_MHZ}MHz"
        
        GPU_MEM=$(vcgencmd get_mem gpu | cut -d'=' -f2)
        echo "   GPU Memory: $GPU_MEM"
        
        THROTTLED=$(vcgencmd get_throttled)
        if [ "$THROTTLED" = "throttled=0x0" ]; then
            echo "   Throttling: None ✅"
        else
            echo "   Throttling: $THROTTLED ⚠️"
        fi
    fi
    
    echo ""
    echo "💾 Memory:"
    free -h | grep -E "Mem|Swap"
    
    echo ""
    echo "💽 Storage:"
    df -h / | tail -1
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main function
main() {
    clear
    echo "🍓 NBA Analytics - Raspberry Pi 4 Quick Start"
    echo "=============================================="
    echo ""
    
    check_pi4
    check_existing_deployment
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1)
                    show_status
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    restart_services
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    if [ -f "./pi-monitor.sh" ]; then
                        chmod +x ./pi-monitor.sh
                        ./pi-monitor.sh
                    else
                        print_error "pi-monitor.sh not found"
                    fi
                    ;;
                4)
                    view_logs
                    ;;
                5)
                    if [ -f "./deploy-pi4-arm64.sh" ]; then
                        print_status "Starting full deployment..."
                        chmod +x ./deploy-pi4-arm64.sh
                        ./deploy-pi4-arm64.sh
                    else
                        print_error "deploy-pi4-arm64.sh not found"
                    fi
                    ;;
                6)
                    show_system_info
                    ;;
                0)
                    echo "Goodbye! 🍓"
                    exit 0
                    ;;
                *)
                    print_error "Invalid choice"
                    read -p "Press Enter to continue..."
                    ;;
            esac
        done
    else
        # Command line mode
        case $1 in
            --status|status)
                show_status
                ;;
            --restart|restart)
                restart_services
                ;;
            --info|info)
                show_system_info
                ;;
            --deploy|deploy)
                if [ -f "./deploy-pi4-arm64.sh" ]; then
                    chmod +x ./deploy-pi4-arm64.sh
                    ./deploy-pi4-arm64.sh
                else
                    print_error "deploy-pi4-arm64.sh not found"
                    exit 1
                fi
                ;;
            --monitor|monitor)
                if [ -f "./pi-monitor.sh" ]; then
                    chmod +x ./pi-monitor.sh
                    ./pi-monitor.sh
                else
                    print_error "pi-monitor.sh not found"
                    exit 1
                fi
                ;;
            --help|help)
                echo "NBA Analytics Pi4 Quick Start"
                echo ""
                echo "Usage: $0 [COMMAND]"
                echo ""
                echo "Commands:"
                echo "  status    Show service status"
                echo "  restart   Restart all services"
                echo "  info      Show system information"
                echo "  deploy    Run full deployment"
                echo "  monitor   Open monitoring interface"
                echo "  help      Show this help"
                echo ""
                echo "Interactive mode: Run without arguments"
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Use --help for available commands"
                exit 1
                ;;
        esac
    fi
}

# Install bc if needed for calculations
if ! command -v bc &> /dev/null; then
    print_status "Installing bc for calculations..."
    sudo apt-get update && sudo apt-get install -y bc
fi

# Run main function
main "$@"