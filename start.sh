#!/bin/bash

# NBA Analysis System - Linux/Debian Quick Start Script
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✅]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️ ]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[📋]${NC} $1"
}

echo "================================================"
echo "🏀 NBA Analysis System - Quick Start"
echo "================================================"
echo ""

print_step "Sprawdzanie gotowości projektu..."
echo ""

# Check if we are in the right directory
if [[ ! -f "package.json" ]]; then
    print_error "Nie jesteś w głównym folderze projektu!"
    echo ""
    echo "Upewnij się, że jesteś w folderze z plikiem package.json"
    exit 1
fi

# Check if setup was run
if [[ ! -d "backend/venv" ]]; then
    print_error "Środowisko Python nie zostało utworzone!"
    echo ""
    echo "🔧 Uruchom najpierw: ./setup.sh"
    exit 1
fi

if [[ ! -d "node_modules" ]]; then
    print_error "Zależności frontend nie zostały zainstalowane!"
    echo ""
    echo "🔧 Uruchom najpierw: ./setup.sh"
    exit 1
fi

if [[ ! -f ".env" ]]; then
    print_error "Plik .env nie istnieje!"
    echo ""
    echo "� Rozwiązania:"
    echo "   1. Uruchom: ./setup.sh (automatyczne tworzenie)"
    echo "   2. Skopiuj .env.example do .env ręcznie" 
    echo "   3. Uzupełnij klucze API w pliku .env"
    exit 1
fi

# Check if .env has required keys
if grep -q "your_supabase_url_here" .env 2>/dev/null; then
    print_warning "Plik .env zawiera przykładowe wartości!"
    echo ""
    echo "🔑 Musisz uzupełnić prawdziwe klucze API:"
    echo "   - VITE_SUPABASE_URL"
    echo "   - VITE_SUPABASE_ANON_KEY"
    echo "   - VITE_ODDS_API_KEY"
    echo ""
    echo "📖 Zobacz dokumentację: README.md"
    echo ""
    read -p "Kontynuować mimo to? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi
    
    # Check health
    if curl -f http://localhost/health &>/dev/null; then
        echo "✅ Services are running!"
        echo ""
        echo "🌐 Frontend: http://localhost"
        echo "🚀 Backend: http://localhost:8000"
        echo "📊 API Docs: http://localhost:8000/docs"
    else
        echo "❌ Services failed to start. Checking logs..."
        docker-compose logs --tail=20
    fi
    
elif command -v pm2 &> /dev/null; then
    echo "⚙️ Using PM2..."
    
    # Create logs directory
    mkdir -p logs
    
    # Build frontend if needed
    if [ ! -d "dist" ]; then
        echo "📦 Building frontend..."
        npm run build
    fi
    
    # Start with PM2
    pm2 start ecosystem.config.json --env production
    
    fi

# Check if backend main.py exists
if [[ ! -f "backend/main.py" ]]; then
    print_error "Brak pliku backend/main.py!"
    echo ""
    echo "Sprawdź strukturę projektu"
    exit 1
fi

# Check port availability
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port 8000 jest zajęty!"
    echo ""
    read -p "Zabić procesy na porcie 8000? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo lsof -ti:8000 | xargs sudo kill -9 2>/dev/null || true
        print_status "Procesy na porcie 8000 zakończone"
    fi
fi

if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port 5173 jest zajęty!"
    echo ""
    read -p "Zabić procesy na porcie 5173? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo lsof -ti:5173 | xargs sudo kill -9 2>/dev/null || true
        print_status "Procesy na porcie 5173 zakończone"
    fi
fi

print_status "Wszystko gotowe! Uruchamiam aplikację..."
echo ""
echo "📋 Uruchomią się 2 procesy w tle:"
echo "   1️⃣  Backend (Python/FastAPI) - port 8000"
echo "   2️⃣  Frontend (React/Vite) - port 5173"
echo ""
echo "⚠️  WAŻNE: Naciśnij Ctrl+C aby zatrzymać oba procesy"
echo ""
echo "🌐 Po uruchomieniu aplikacja będzie dostępna na:"
echo "   Frontend: http://localhost:5173"
echo "   API: http://localhost:8000/docs"
echo ""
read -p "Kontynuować uruchomienie? (Y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
fi

echo ""
print_step "� Uruchamiam backend..."

# Start backend in background
cd backend
source venv/bin/activate
python main.py &
BACKEND_PID=$!
cd ..

echo "✅ Backend uruchomiony (PID: $BACKEND_PID)"
echo "⏳ Czekam 4 sekundy na uruchomienie backendu..."
sleep 4

print_step "🚀 Uruchamiam frontend..."

# Start frontend in background  
npm run dev &
FRONTEND_PID=$!

echo "✅ Frontend uruchomiony (PID: $FRONTEND_PID)"
echo ""
echo "✅ APLIKACJA URUCHOMIONA POMYŚLNIE!"
echo ""
echo "🌐 DOSTĘP DO APLIKACJI:"
echo "   📱 Frontend:  http://localhost:5173"
echo "   🔌 API:       http://localhost:8000"
echo "   📚 API Docs:  http://localhost:8000/docs"
echo "   💾 Health:    http://localhost:8000/health"
echo ""
echo "🎯 FUNKCJE DOSTĘPNE:"
echo "   📊 Dashboard NBA z analizami"
echo "   🏀 Chicago Bulls - analiza graczy"
echo "   💰 Rekomendacje zakładów (Kelly Criterion)"
echo "   � Raporty automatyczne (7:50, 8:00, 11:00)"
echo "   🎲 Live odds monitoring"
echo ""

# Wait for Ctrl+C
trap 'echo ""; echo "🛑 Zatrzymywanie aplikacji..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo "✅ Aplikacja zatrzymana"; exit 0' INT

echo "⚠️  Naciśnij Ctrl+C aby zatrzymać aplikację"
echo ""

# Try to open browser if available
if command -v xdg-open >/dev/null 2>&1; then
    echo "🚀 Otwieranie w przeglądarce..."
    sleep 2
    xdg-open http://localhost:5173 >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    echo "🚀 Otwieranie w przeglądarce..."
    sleep 2
    open http://localhost:5173 >/dev/null 2>&1 &
fi

echo "✨ Aplikacja działa! Monitoruję procesy..."
echo "   Backend PID: $BACKEND_PID"
echo "   Frontend PID: $FRONTEND_PID"

# Monitor processes
while kill -0 $BACKEND_PID 2>/dev/null && kill -0 $FRONTEND_PID 2>/dev/null; do
    sleep 5
done

print_error "Jeden z procesów się zakończył!"
echo "🔍 Sprawdź logi w terminalach"
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    
else
    echo "⚡ Using development mode..."
    
    # Start backend
    cd backend
    python -m uvicorn main:app --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    cd ..
    
    # Start frontend
    npm run dev -- --host 0.0.0.0 --port 5173 &
    FRONTEND_PID=$!
    
    echo "✅ Services started in development mode!"
    echo ""
    echo "🌐 Frontend: http://localhost:5173"
    echo "🚀 Backend: http://localhost:8000"
    echo ""
    echo "Press Ctrl+C to stop services"
    
    # Wait for user interrupt
    trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT
    wait
fi