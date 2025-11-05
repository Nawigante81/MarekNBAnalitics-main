#!/bin/bash

# NBA Analytics - Raspberry Pi 4 ARM64 System Checker
# Run this before deployment to check system compatibility

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}🍓 NBA Analytics Pi4 System Checker 🍓${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# System compatibility checks
check_system() {
    print_check "Checking system compatibility..."
    
    # Check if Raspberry Pi
    if [ -f /proc/cpuinfo ]; then
        if grep -q "Raspberry Pi" /proc/cpuinfo; then
            MODEL=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | xargs)
            print_ok "Device: $MODEL"
            
            if grep -q "Raspberry Pi 4" /proc/cpuinfo; then
                print_ok "✅ Raspberry Pi 4 detected"
            else
                print_warning "⚠️  Not Pi4 - may have limited performance"
            fi
        else
            print_error "❌ Not a Raspberry Pi device"
            return 1
        fi
    else
        print_error "❌ Cannot detect device type"
        return 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        print_ok "✅ ARM64 architecture: $ARCH"
    else
        print_error "❌ Wrong architecture: $ARCH (need ARM64/aarch64)"
        return 1
    fi
    
    return 0
}

# OS compatibility check
check_os() {
    print_check "Checking operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "OS: $PRETTY_NAME"
        print_info "Version: $VERSION"
        
        # Check if Debian-based
        if [[ "$ID" == "debian" || "$ID_LIKE" == *"debian"* || "$ID" == "raspbian" ]]; then
            print_ok "✅ Debian-based OS detected"
            
            # Check version
            VERSION_ID_NUM=$(echo $VERSION_ID | cut -d. -f1)
            if [ "$VERSION_ID_NUM" -ge 11 ]; then
                print_ok "✅ OS version compatible"
            else
                print_warning "⚠️  Old OS version, consider upgrade"
            fi
        else
            print_warning "⚠️  Non-Debian OS, may need manual adjustments"
        fi
    else
        print_error "❌ Cannot detect OS version"
        return 1
    fi
    
    return 0
}

# Memory check
check_memory() {
    print_check "Checking memory..."
    
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAIL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    print_info "Total Memory: ${TOTAL_MEM}MB"
    print_info "Available Memory: ${AVAIL_MEM}MB"
    
    if [ "$TOTAL_MEM" -ge 3800 ]; then
        print_ok "✅ Sufficient memory: ${TOTAL_MEM}MB"
    elif [ "$TOTAL_MEM" -ge 1800 ]; then
        print_warning "⚠️  Limited memory: ${TOTAL_MEM}MB - will enable swap"
    else
        print_error "❌ Insufficient memory: ${TOTAL_MEM}MB (need at least 2GB)"
        return 1
    fi
    
    # Check swap
    SWAP_TOTAL=$(free -m | awk 'NR==3{printf "%.0f", $2}')
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        print_ok "✅ Swap available: ${SWAP_TOTAL}MB"
    else
        print_warning "⚠️  No swap configured - will be created during deployment"
    fi
    
    return 0
}

# Storage check
check_storage() {
    print_check "Checking storage..."
    
    ROOT_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    ROOT_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
    ROOT_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
    
    print_info "Root filesystem: ${ROOT_AVAIL} available of ${ROOT_TOTAL} total"
    print_info "Usage: ${ROOT_USAGE}%"
    
    if [ "$ROOT_USAGE" -lt 70 ]; then
        print_ok "✅ Sufficient storage space"
    elif [ "$ROOT_USAGE" -lt 85 ]; then
        print_warning "⚠️  Limited storage space: ${ROOT_USAGE}% used"
    else
        print_error "❌ Low storage space: ${ROOT_USAGE}% used"
        return 1
    fi
    
    # Check SD card speed (if available)
    if [ -f /sys/block/mmcblk0/queue/read_ahead_kb ]; then
        print_info "SD card detected"
        # Check if it's a fast card
        if command -v hdparm &> /dev/null; then
            SD_SPEED=$(sudo hdparm -t /dev/mmcblk0 2>/dev/null | grep "Timing buffered disk reads" | awk '{print $11}')
            if [ -n "$SD_SPEED" ]; then
                print_info "SD card speed: ${SD_SPEED} MB/sec"
            fi
        fi
    fi
    
    return 0
}

# Network check
check_network() {
    print_check "Checking network connectivity..."
    
    # Check internet connectivity
    if ping -c 1 google.com &> /dev/null; then
        print_ok "✅ Internet connectivity working"
    else
        print_error "❌ No internet connectivity"
        return 1
    fi
    
    # Check DNS resolution
    if nslookup github.com &> /dev/null; then
        print_ok "✅ DNS resolution working"
    else
        print_warning "⚠️  DNS resolution issues"
    fi
    
    # Check network interfaces
    INTERFACES=$(ip link show | grep -E "^[0-9]+:" | grep -v lo | wc -l)
    print_info "Network interfaces: $INTERFACES"
    
    # Check if WiFi is available
    if iwconfig 2>/dev/null | grep -q "wlan0"; then
        WIFI_SIGNAL=$(iwconfig wlan0 2>/dev/null | grep "Signal level" | awk '{print $4}' | cut -d'=' -f2)
        if [ -n "$WIFI_SIGNAL" ]; then
            print_info "WiFi signal: $WIFI_SIGNAL"
        fi
    fi
    
    return 0
}

# Package manager check
check_package_manager() {
    print_check "Checking package manager..."
    
    # Check if apt is working
    if command -v apt-get &> /dev/null; then
        print_ok "✅ apt-get available"
        
        # Test package list update
        print_info "Testing package list update..."
        if sudo apt-get update &> /dev/null; then
            print_ok "✅ Package lists can be updated"
        else
            print_error "❌ Cannot update package lists"
            print_info "Try: sudo apt-get update"
            return 1
        fi
        
        # Check for broken packages
        BROKEN=$(apt list --upgradable 2>/dev/null | wc -l)
        if [ "$BROKEN" -gt 1 ]; then
            print_info "Upgradable packages: $((BROKEN-1))"
        fi
        
    else
        print_error "❌ apt-get not available"
        return 1
    fi
    
    return 0
}

# Hardware health check
check_hardware() {
    print_check "Checking hardware health..."
    
    if command -v vcgencmd &> /dev/null; then
        # CPU temperature
        CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        print_info "CPU Temperature: ${CPU_TEMP}°C"
        
        if (( $(echo "$CPU_TEMP < 70" | bc -l) )); then
            print_ok "✅ CPU temperature normal"
        elif (( $(echo "$CPU_TEMP < 80" | bc -l) )); then
            print_warning "⚠️  CPU temperature elevated: ${CPU_TEMP}°C"
        else
            print_error "❌ CPU temperature critical: ${CPU_TEMP}°C"
        fi
        
        # Check throttling
        THROTTLED=$(vcgencmd get_throttled)
        if [ "$THROTTLED" = "throttled=0x0" ]; then
            print_ok "✅ No throttling detected"
        else
            print_warning "⚠️  Throttling detected: $THROTTLED"
        fi
        
        # CPU frequency
        CPU_FREQ=$(vcgencmd measure_clock arm | cut -d= -f2)
        CPU_FREQ_MHZ=$(echo "scale=0; $CPU_FREQ/1000000" | bc)
        print_info "CPU Frequency: ${CPU_FREQ_MHZ}MHz"
        
        # Voltage
        CORE_VOLT=$(vcgencmd measure_volts core | cut -d'=' -f2)
        print_info "Core Voltage: $CORE_VOLT"
        
    else
        print_warning "⚠️  vcgencmd not available, cannot check Pi hardware"
    fi
    
    return 0
}

# Required software check
check_required_software() {
    print_check "Checking for required software..."
    
    # Check essential commands
    REQUIRED_COMMANDS=("curl" "wget" "git" "python3" "pip3")
    missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            print_ok "✅ $cmd available"
        else
            print_warning "⚠️  $cmd missing (will be installed)"
            missing_commands+=("$cmd")
        fi
    done
    
    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        
        print_info "Python version: $PYTHON_VERSION"
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
            print_ok "✅ Python version compatible"
        else
            print_warning "⚠️  Python version may be too old"
        fi
    fi
    
    # Check Node.js if available
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_info "Node.js version: $NODE_VERSION"
        print_ok "✅ Node.js available"
    else
        print_warning "⚠️  Node.js not installed (will be installed)"
    fi
    
    return 0
}

# Performance recommendations
show_recommendations() {
    echo ""
    echo -e "${PURPLE}📋 Optimization Recommendations${NC}"
    echo ""
    
    # Memory recommendations
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ "$TOTAL_MEM" -lt 3800 ]; then
        echo -e "${YELLOW}💾 Memory Optimization:${NC}"
        echo "  • Consider enabling swap for better performance"
        echo "  • Reduce GPU memory split: sudo raspi-config -> Advanced -> Memory Split -> 64"
        echo ""
    fi
    
    # Temperature recommendations
    if command -v vcgencmd &> /dev/null; then
        CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        if (( $(echo "$CPU_TEMP > 60" | bc -l) )); then
            echo -e "${YELLOW}🌡️  Cooling Recommendations:${NC}"
            echo "  • Install heatsink or cooling fan"
            echo "  • Ensure proper ventilation"
            echo "  • Monitor temperature during deployment"
            echo ""
        fi
    fi
    
    # Storage recommendations
    ROOT_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$ROOT_USAGE" -gt 60 ]; then
        echo -e "${YELLOW}💽 Storage Optimization:${NC}"
        echo "  • Clean up old logs: sudo journalctl --vacuum-size=100M"
        echo "  • Remove unused packages: sudo apt autoremove"
        echo "  • Consider larger SD card for better performance"
        echo ""
    fi
    
    # Network recommendations
    if iwconfig 2>/dev/null | grep -q "wlan0"; then
        echo -e "${YELLOW}🌐 Network Optimization:${NC}"
        echo "  • Use Ethernet connection for better performance"
        echo "  • Ensure strong WiFi signal if using wireless"
        echo ""
    fi
    
    echo -e "${GREEN}🚀 Ready for deployment!${NC}"
    echo "Run: ./deploy-pi4-arm64.sh"
}

# Main function
main() {
    print_header
    
    echo "This tool checks if your Raspberry Pi 4 is ready for NBA Analytics deployment."
    echo ""
    
    # Install bc if needed
    if ! command -v bc &> /dev/null; then
        print_info "Installing bc for calculations..."
        sudo apt-get update &> /dev/null && sudo apt-get install -y bc &> /dev/null
    fi
    
    # Run all checks
    checks_passed=0
    total_checks=7
    
    if check_system; then ((checks_passed++)); fi
    echo ""
    
    if check_os; then ((checks_passed++)); fi
    echo ""
    
    if check_memory; then ((checks_passed++)); fi
    echo ""
    
    if check_storage; then ((checks_passed++)); fi
    echo ""
    
    if check_network; then ((checks_passed++)); fi
    echo ""
    
    if check_package_manager; then ((checks_passed++)); fi
    echo ""
    
    if check_hardware; then ((checks_passed++)); fi
    echo ""
    
    check_required_software
    echo ""
    
    # Summary
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}📊 System Check Summary${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    if [ "$checks_passed" -eq "$total_checks" ]; then
        print_ok "✅ All critical checks passed ($checks_passed/$total_checks)"
        echo ""
        show_recommendations
    elif [ "$checks_passed" -ge $((total_checks - 1)) ]; then
        print_warning "⚠️  Most checks passed ($checks_passed/$total_checks)"
        echo ""
        echo -e "${YELLOW}You can proceed with deployment, but monitor for issues.${NC}"
        show_recommendations
    else
        print_error "❌ Multiple checks failed ($checks_passed/$total_checks)"
        echo ""
        echo -e "${RED}Please fix the issues above before deployment.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"