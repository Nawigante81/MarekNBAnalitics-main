#!/bin/bash
# =================================================================
# NBA Analytics - Docker Host Optimization Script
# =================================================================
# This script optimizes the Docker host for Redis and other services

echo "🔧 NBA Analytics - Optimizing Docker Host..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Set vm.overcommit_memory=1 for Redis
echo "📝 Setting vm.overcommit_memory=1 for Redis..."
sysctl -w vm.overcommit_memory=1

# Make it persistent across reboots
if ! grep -q "vm.overcommit_memory=1" /etc/sysctl.conf; then
    echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
    echo "✅ Added vm.overcommit_memory=1 to /etc/sysctl.conf"
else
    echo "✅ vm.overcommit_memory=1 already in /etc/sysctl.conf"
fi

# Set vm.swappiness for better Docker performance  
echo "📝 Setting vm.swappiness=10 for better Docker performance..."
sysctl -w vm.swappiness=10

if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "✅ Added vm.swappiness=10 to /etc/sysctl.conf"
else
    echo "✅ vm.swappiness=10 already in /etc/sysctl.conf"
fi

# Display current settings
echo ""
echo "🔍 Current kernel parameters:"
echo "vm.overcommit_memory = $(sysctl -n vm.overcommit_memory)"
echo "vm.swappiness = $(sysctl -n vm.swappiness)"

echo ""
echo "✅ Host optimization complete!"
echo "💡 Note: These settings will persist after reboot"