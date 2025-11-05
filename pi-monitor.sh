#!/bin/bash

# NBA Analytics - Raspberry Pi 4 ARM64 Monitoring Script
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}🍓 NBA Analytics Pi4 Monitor 🍓${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

print_metric() {
    echo -e "  ${GREEN}$1:${NC} $2"
}

print_warning() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "  ${RED}❌ $1${NC}"
}

print_ok() {
    echo -e "  ${GREEN}✅ $1${NC}"
}

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if [ ! -f /proc/cpuinfo ] || ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        echo -e "${RED}Error: This script is designed for Raspberry Pi${NC}"
        exit 1
    fi
    
    MODEL=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | xargs)
    echo -e "${PURPLE}Hardware: $MODEL${NC}"
    echo ""
}

# System Information
show_system_info() {
    print_section "📋 System Information"
    
    # Raspberry Pi Model
    if [ -f /proc/cpuinfo ]; then
        MODEL=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | xargs)
        print_metric "Model" "$MODEL"
        
        SERIAL=$(grep "Serial" /proc/cpuinfo | cut -d':' -f2 | xargs)
        print_metric "Serial" "$SERIAL"
    fi
    
    # OS Information
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_metric "OS" "$PRETTY_NAME"
    fi
    
    # Kernel
    KERNEL=$(uname -r)
    print_metric "Kernel" "$KERNEL"
    
    # Architecture
    ARCH=$(uname -m)
    print_metric "Architecture" "$ARCH"
    
    # Uptime
    UPTIME=$(uptime -p)
    print_metric "Uptime" "$UPTIME"
    
    echo ""
}

# Hardware Status
show_hardware_status() {
    print_section "🔧 Hardware Status"
    
    # CPU Temperature
    if command -v vcgencmd &> /dev/null; then
        CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
        TEMP_NUM=$(echo $CPU_TEMP | cut -d"'" -f1)
        
        if (( $(echo "$TEMP_NUM > 80" | bc -l) )); then
            print_error "CPU Temperature: $CPU_TEMP (CRITICAL)"
        elif (( $(echo "$TEMP_NUM > 70" | bc -l) )); then
            print_warning "CPU Temperature: $CPU_TEMP (HIGH)"
        else
            print_metric "CPU Temperature" "$CPU_TEMP"
        fi
        
        # CPU Frequency
        CPU_FREQ=$(vcgencmd measure_clock arm | cut -d= -f2)
        CPU_FREQ_MHZ=$(echo "scale=0; $CPU_FREQ/1000000" | bc)
        print_metric "CPU Frequency" "${CPU_FREQ_MHZ}MHz"
        
        # GPU Memory
        GPU_MEM=$(vcgencmd get_mem gpu | cut -d'=' -f2)
        print_metric "GPU Memory" "$GPU_MEM"
        
        # Throttling Status
        THROTTLED=$(vcgencmd get_throttled)
        if [ "$THROTTLED" = "throttled=0x0" ]; then
            print_ok "No throttling detected"
        else
            print_warning "Throttling detected: $THROTTLED"
        fi
    fi
    
    # Voltage
    if command -v vcgencmd &> /dev/null; then
        CORE_VOLT=$(vcgencmd measure_volts core | cut -d'=' -f2)
        print_metric "Core Voltage" "$CORE_VOLT"
    fi
    
    echo ""
}

# Memory and Storage
show_memory_storage() {
    print_section "💾 Memory & Storage"
    
    # Memory usage
    MEM_INFO=$(free -h | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_FREE=$(echo $MEM_INFO | awk '{print $4}')
    MEM_AVAIL=$(echo $MEM_INFO | awk '{print $7}')
    
    print_metric "Memory Total" "$MEM_TOTAL"
    print_metric "Memory Used" "$MEM_USED"
    print_metric "Memory Free" "$MEM_FREE"
    print_metric "Memory Available" "$MEM_AVAIL"
    
    # Memory usage percentage
    MEM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$MEM_PERCENT > 90" | bc -l) )); then
        print_error "Memory Usage: ${MEM_PERCENT}% (CRITICAL)"
    elif (( $(echo "$MEM_PERCENT > 80" | bc -l) )); then
        print_warning "Memory Usage: ${MEM_PERCENT}% (HIGH)"
    else
        print_metric "Memory Usage" "${MEM_PERCENT}%"
    fi
    
    # Swap usage
    SWAP_INFO=$(free -h | grep Swap)
    if [ -n "$SWAP_INFO" ]; then
        SWAP_TOTAL=$(echo $SWAP_INFO | awk '{print $2}')
        SWAP_USED=$(echo $SWAP_INFO | awk '{print $3}')
        print_metric "Swap Total" "$SWAP_TOTAL"
        print_metric "Swap Used" "$SWAP_USED"
    fi
    
    # Disk usage (root filesystem)
    DISK_INFO=$(df -h / | tail -1)
    DISK_SIZE=$(echo $DISK_INFO | awk '{print $2}')
    DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
    DISK_AVAIL=$(echo $DISK_INFO | awk '{print $4}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $5}' | sed 's/%//')
    
    print_metric "Disk Size" "$DISK_SIZE"
    print_metric "Disk Used" "$DISK_USED"
    print_metric "Disk Available" "$DISK_AVAIL"
    
    if [ "$DISK_PERCENT" -gt 90 ]; then
        print_error "Disk Usage: ${DISK_PERCENT}% (CRITICAL)"
    elif [ "$DISK_PERCENT" -gt 80 ]; then
        print_warning "Disk Usage: ${DISK_PERCENT}% (HIGH)"
    else
        print_metric "Disk Usage" "${DISK_PERCENT}%"
    fi
    
    echo ""
}

# CPU Load
show_cpu_load() {
    print_section "⚡ CPU Load"
    
    # Load averages
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
    print_metric "Load Average" "$LOAD_AVG"
    
    # CPU cores
    CPU_CORES=$(nproc)
    print_metric "CPU Cores" "$CPU_CORES"
    
    # Top processes by CPU
    echo -e "  ${GREEN}Top CPU Processes:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        PROCESS=$(echo $line | awk '{print $11}')
        CPU=$(echo $line | awk '{print $3}')
        echo -e "    ${YELLOW}${PROCESS} (${CPU}%)${NC}"
    done
    
    echo ""
}

# Network Status
show_network_status() {
    print_section "🌐 Network Status"
    
    # Network interfaces
    for interface in $(ip link show | grep -E "^[0-9]+:" | grep -v lo | cut -d: -f2 | tr -d ' '); do
        STATUS=$(ip link show $interface | grep -o "state [A-Z]*" | cut -d' ' -f2)
        
        if [ "$STATUS" = "UP" ]; then
            print_ok "$interface: $STATUS"
            
            # Get IP address
            IP=$(ip addr show $interface | grep "inet " | awk '{print $2}' | cut -d/ -f1)
            if [ -n "$IP" ]; then
                print_metric "  IP Address" "$IP"
            fi
        else
            print_error "$interface: $STATUS"
        fi
    done
    
    # WiFi signal strength (if available)
    if command -v iwconfig &> /dev/null; then
        WIFI_INFO=$(iwconfig 2>/dev/null | grep -A 5 wlan0 | grep "Signal level")
        if [ -n "$WIFI_INFO" ]; then
            SIGNAL=$(echo $WIFI_INFO | awk '{print $4}' | cut -d'=' -f2)
            print_metric "WiFi Signal" "$SIGNAL"
        fi
    fi
    
    echo ""
}

# Service Status
show_service_status() {
    print_section "🚀 NBA Analytics Services"
    
    services=("nba-backend" "nba-frontend" "caddy")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            print_ok "$service is running"
            
            # Show memory usage for the service
            PID=$(systemctl show --property MainPID --value $service)
            if [ "$PID" != "0" ] && [ -n "$PID" ]; then
                MEM_USAGE=$(ps -p $PID -o rss= 2>/dev/null | awk '{printf "%.1fMB", $1/1024}')
                if [ -n "$MEM_USAGE" ]; then
                    print_metric "  Memory Usage" "$MEM_USAGE"
                fi
            fi
        else
            print_error "$service is not running"
        fi
    done
    
    echo ""
}

# Application Health
show_app_health() {
    print_section "🏥 Application Health"
    
    # Backend health check
    if curl -f -s --connect-timeout 5 http://localhost:8000/health > /dev/null; then
        print_ok "Backend API responding"
    else
        print_error "Backend API not responding"
    fi
    
    # Frontend health check  
    if curl -f -s --connect-timeout 5 http://localhost:5173/ > /dev/null; then
        print_ok "Frontend responding"
    else
        print_warning "Frontend not responding - may be normal"
    fi
    
    # Caddy health check
    if curl -f -s --connect-timeout 5 http://localhost/health > /dev/null; then
        print_ok "Caddy proxy responding"
    else
        print_error "Caddy proxy not responding"
    fi
    
    echo ""
}

# Logs
show_recent_logs() {
    print_section "📋 Recent Logs (last 5 lines each)"
    
    services=("nba-backend" "nba-frontend" "caddy")
    
    for service in "${services[@]}"; do
        echo -e "  ${YELLOW}$service:${NC}"
        if systemctl is-active --quiet $service; then
            journalctl -u $service --no-pager -n 3 --since "10 minutes ago" | tail -3 | while read line; do
                echo -e "    ${BLUE}$(echo $line | cut -c1-80)${NC}"
            done
        else
            echo -e "    ${RED}Service not running${NC}"
        fi
        echo ""
    done
}

# Performance Recommendations
show_recommendations() {
    print_section "💡 Performance Recommendations"
    
    # Temperature check
    if command -v vcgencmd &> /dev/null; then
        TEMP_NUM=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        if (( $(echo "$TEMP_NUM > 70" | bc -l) )); then
            print_warning "Consider better cooling - temperature is ${TEMP_NUM}°C"
        fi
    fi
    
    # Memory check
    MEM_PERCENT=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEM_PERCENT" -gt 80 ]; then
        print_warning "High memory usage (${MEM_PERCENT}%) - consider enabling swap or reducing services"
    fi
    
    # Disk check
    DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_PERCENT" -gt 80 ]; then
        print_warning "High disk usage (${DISK_PERCENT}%) - clean up old logs and files"
    fi
    
    # Load check
    LOAD_1=$(uptime | awk '{print $(NF-2)}' | sed 's/,//')
    CPU_CORES=$(nproc)
    if (( $(echo "$LOAD_1 > $CPU_CORES" | bc -l) )); then
        print_warning "High CPU load ($LOAD_1 on $CPU_CORES cores) - check processes"
    fi
    
    echo ""
}

# Interactive menu
show_menu() {
    echo -e "${CYAN}Choose monitoring option:${NC}"
    echo "1) Full system report"
    echo "2) Quick status check"
    echo "3) Live monitoring (press Ctrl+C to stop)"
    echo "4) Service management"
    echo "5) Performance optimization tips"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice [0-5]: " choice
}

# Service management
manage_services() {
    print_section "🔧 Service Management"
    
    echo "1) Restart all services"
    echo "2) Stop all services"
    echo "3) Start all services"
    echo "4) View service logs"
    echo "0) Back to main menu"
    echo ""
    read -p "Enter your choice [0-4]: " service_choice
    
    services=("nba-backend" "nba-frontend" "caddy")
    
    case $service_choice in
        1)
            echo "Restarting all services..."
            for service in "${services[@]}"; do
                echo "Restarting $service..."
                sudo systemctl restart $service
            done
            echo "All services restarted"
            ;;
        2)
            echo "Stopping all services..."
            for service in "${services[@]}"; do
                echo "Stopping $service..."
                sudo systemctl stop $service
            done
            echo "All services stopped"
            ;;
        3)
            echo "Starting all services..."
            for service in "${services[@]}"; do
                echo "Starting $service..."
                sudo systemctl start $service
            done
            echo "All services started"
            ;;
        4)
            echo "Select service to view logs:"
            for i in "${!services[@]}"; do
                echo "$((i+1))) ${services[$i]}"
            done
            read -p "Enter choice: " log_choice
            if [ "$log_choice" -ge 1 ] && [ "$log_choice" -le "${#services[@]}" ]; then
                service="${services[$((log_choice-1))]}"
                echo "Showing logs for $service (press Ctrl+C to exit):"
                sudo journalctl -u $service -f
            fi
            ;;
        0)
            return
            ;;
    esac
}

# Performance optimization tips
show_optimization_tips() {
    print_section "🚀 Raspberry Pi 4 Optimization Tips"
    
    echo -e "${GREEN}Memory Optimization:${NC}"
    echo "  • Increase GPU memory split: sudo raspi-config > Advanced > Memory Split > 64"
    echo "  • Enable swap if needed: sudo dphys-swapfile setup && sudo dphys-swapfile swapon"
    echo "  • Monitor memory: watch free -h"
    echo ""
    
    echo -e "${GREEN}CPU Optimization:${NC}"
    echo "  • Monitor temperature: watch vcgencmd measure_temp"
    echo "  • Check throttling: watch vcgencmd get_throttled"
    echo "  • Improve cooling with heatsinks/fan"
    echo ""
    
    echo -e "${GREEN}Storage Optimization:${NC}"
    echo "  • Use fast SD card (Class 10, A1/A2)"
    echo "  • Clean logs: sudo journalctl --vacuum-size=100M"
    echo "  • Remove unused packages: sudo apt autoremove"
    echo ""
    
    echo -e "${GREEN}Network Optimization:${NC}"
    echo "  • Use Ethernet for better performance"
    echo "  • Check WiFi signal: iwconfig"
    echo "  • Monitor network: iftop"
    echo ""
    
    echo -e "${GREEN}Application Optimization:${NC}"
    echo "  • Reduce worker processes for lower memory usage"
    echo "  • Use PM2 for process management"
    echo "  • Enable gzip compression in Caddy"
    echo ""
}

# Live monitoring
live_monitoring() {
    print_section "📊 Live Monitoring (Press Ctrl+C to stop)"
    
    while true; do
        clear
        print_header
        
        # Essential metrics only for live view
        if command -v vcgencmd &> /dev/null; then
            CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
            echo -e "${GREEN}Temperature:${NC} $CPU_TEMP"
        fi
        
        MEM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        echo -e "${GREEN}Memory Usage:${NC} ${MEM_PERCENT}%"
        
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
        echo -e "${GREEN}Load Average:${NC}$LOAD_AVG"
        
        # Service status
        echo ""
        echo -e "${CYAN}Services:${NC}"
        for service in nba-backend nba-frontend caddy; do
            if systemctl is-active --quiet $service; then
                echo -e "  ${GREEN}✅ $service${NC}"
            else
                echo -e "  ${RED}❌ $service${NC}"
            fi
        done
        
        echo ""
        echo "Press Ctrl+C to stop live monitoring"
        sleep 5
    done
}

# Main script
main() {
    print_header
    check_raspberry_pi
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1)
                    clear
                    print_header
                    show_system_info
                    show_hardware_status
                    show_memory_storage
                    show_cpu_load
                    show_network_status
                    show_service_status
                    show_app_health
                    show_recent_logs
                    show_recommendations
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    clear
                    print_header
                    show_hardware_status
                    show_service_status
                    show_app_health
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    live_monitoring
                    ;;
                4)
                    manage_services
                    ;;
                5)
                    clear
                    print_header
                    show_optimization_tips
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    echo "Goodbye! 🍓"
                    exit 0
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
        done
    else
        # Command line mode
        case $1 in
            --full)
                show_system_info
                show_hardware_status
                show_memory_storage
                show_cpu_load
                show_network_status
                show_service_status
                show_app_health
                show_recommendations
                ;;
            --quick)
                show_hardware_status
                show_service_status
                show_app_health
                ;;
            --live)
                live_monitoring
                ;;
            --services)
                show_service_status
                ;;
            --health)
                show_app_health
                ;;
            --temp)
                if command -v vcgencmd &> /dev/null; then
                    vcgencmd measure_temp
                else
                    echo "vcgencmd not available"
                fi
                ;;
            --help)
                echo "NBA Analytics Raspberry Pi 4 Monitor"
                echo ""
                echo "Usage: $0 [OPTION]"
                echo ""
                echo "Options:"
                echo "  --full      Full system report"
                echo "  --quick     Quick status check"
                echo "  --live      Live monitoring"
                echo "  --services  Service status only"
                echo "  --health    Application health only"
                echo "  --temp      CPU temperature only"
                echo "  --help      Show this help message"
                echo ""
                echo "Interactive mode: Run without arguments"
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for available options"
                exit 1
                ;;
        esac
    fi
}

# Check for required commands
if ! command -v bc &> /dev/null; then
    echo "Installing bc for calculations..."
    sudo apt-get update && sudo apt-get install -y bc
fi

# Run main function
main "$@"