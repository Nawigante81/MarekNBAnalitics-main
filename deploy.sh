#!/bin/bash

# NBA Analytics Production Deployment Script
set -e

echo "🏀 Starting NBA Analytics Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    print_error ".env.production file not found!"
    print_warning "Please copy .env.example to .env.production and configure it"
    exit 1
fi

# Create logs directory
mkdir -p logs
mkdir -p ssl

print_status "Installing dependencies..."

# Install frontend dependencies
print_status "Installing frontend dependencies..."
npm install

# Install backend dependencies
print_status "Installing backend dependencies..."
cd backend
pip install -r requirements.txt
cd ..

# Build frontend
print_status "Building frontend for production..."
npm run build

# Create SSL directory if it doesn't exist
if [ ! -d "ssl" ]; then
    mkdir ssl
    print_warning "SSL directory created. Please add your SSL certificates to ./ssl/"
fi

# Check Docker installation
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Ask user for deployment method
echo ""
echo "Choose deployment method:"
echo "1) Docker Compose (Recommended)"
echo "2) PM2 (Node.js process manager)"
echo "3) Systemd services"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        print_status "Deploying with Docker Compose..."
        
        # Stop existing containers
        docker-compose down 2>/dev/null || true
        
        # Build and start containers
        docker-compose up --build -d
        
        # Wait for services to be ready
        print_status "Waiting for services to start..."
        sleep 30
        
        # Check if services are running
        if docker-compose ps | grep -q "Up"; then
            print_status "✅ Services are running!"
            echo ""
            echo "Frontend: http://localhost"
            echo "Backend: http://localhost:8000"
            echo "Health check: http://localhost/health"
        else
            print_error "❌ Services failed to start. Check logs:"
            docker-compose logs
            exit 1
        fi
        ;;
        
    2)
        print_status "Deploying with PM2..."
        
        # Check if PM2 is installed
        if ! command -v pm2 &> /dev/null; then
            print_status "Installing PM2..."
            npm install -g pm2
        fi
        
        # Stop existing processes
        pm2 delete ecosystem.config.json 2>/dev/null || true
        
        # Start processes
        pm2 start ecosystem.config.json --env production
        
        # Save PM2 configuration
        pm2 save
        
        # Setup PM2 startup script
        pm2 startup
        
        print_status "✅ PM2 deployment complete!"
        echo ""
        echo "PM2 status: pm2 status"
        echo "PM2 logs: pm2 logs"
        echo "PM2 monitoring: pm2 monit"
        ;;
        
    3)
        print_status "Creating systemd services..."
        
        # Create systemd service files
        sudo tee /etc/systemd/system/nba-backend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)/backend
Environment=PATH=$(which python)
ExecStart=$(which uvicorn) main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        sudo tee /etc/systemd/system/nba-frontend.service > /dev/null <<EOF
[Unit]
Description=NBA Analytics Frontend  
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(which npm) run preview -- --host 0.0.0.0 --port 5173
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd and start services
        sudo systemctl daemon-reload
        sudo systemctl enable nba-backend nba-frontend
        sudo systemctl start nba-backend nba-frontend
        
        print_status "✅ Systemd services created and started!"
        echo ""
        echo "Status: sudo systemctl status nba-backend nba-frontend"
        echo "Logs: sudo journalctl -u nba-backend -f"
        ;;
        
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

print_status "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Configure your domain DNS to point to this server"
echo "2. Set up SSL certificates in ./ssl/ directory"
echo "3. Update nginx configuration with your domain"
echo "4. Configure firewall to allow ports 80, 443, 8000"
echo ""
echo "Monitoring commands:"
echo "- Health check: curl http://localhost/health"
echo "- Backend API: curl http://localhost:8000/api/status"
echo "- View logs: docker-compose logs -f (if using Docker)"