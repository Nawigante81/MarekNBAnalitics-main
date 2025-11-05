#!/bin/bash

# NBA Analysis & Betting System - Linux/Debian Setup Script
# This script sets up the development environment with enhanced error handling

set -e  # Exit on any error

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
echo "🏀 NBA Analysis & Betting System - Linux Setup"
echo "================================================"
echo ""

print_step "[1/6] Sprawdzanie środowiska systemowego..."
echo ""

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    print_status "Wykryty system: $OS $VER"
else
    print_warning "Nie można wykryć wersji systemu"
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Uruchamiasz jako root. Rozważ użycie zwykłego użytkownika dla bezpieczeństwa."
fi

# Check package managers
if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    PKG_UPDATE="sudo apt update"
    PKG_INSTALL="sudo apt install -y"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    PKG_UPDATE="sudo yum update"
    PKG_INSTALL="sudo yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    PKG_UPDATE="sudo dnf update"
    PKG_INSTALL="sudo dnf install -y"
else
    print_error "Nie znaleziono obsługiwanego menedżera pakietów (apt/yum/dnf)"
    exit 1
fi
print_status "Menedżer pakietów: $PKG_MGR"
echo ""

print_step "[2/6] Sprawdzanie wymagań..."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js nie jest zainstalowany!"
    echo ""
    echo "🔧 Instalacja Node.js:"
    if [[ "$PKG_MGR" == "apt" ]]; then
        echo "   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        echo "   sudo apt-get install -y nodejs"
    else
        echo "   $PKG_INSTALL nodejs npm"
    fi
    echo ""
    exit 1
fi

NODE_VERSION=$(node --version)
print_status "Node.js $NODE_VERSION"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    print_error "npm nie jest dostępny!"
    echo ""
    echo "Zainstaluj npm: $PKG_INSTALL npm"
    exit 1
fi

NPM_VERSION=$(npm --version)
print_status "npm $NPM_VERSION"

# Check if Python is installed
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    print_error "Python nie jest zainstalowany!"
    echo ""
    echo "🔧 Instalacja Python:"
    echo "   $PKG_INSTALL python3 python3-pip python3-venv"
    echo ""
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version)
print_status "$PYTHON_VERSION"

# Check Python version (should be 3.8+)
PYTHON_VER=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$(echo "$PYTHON_VER < 3.8" | bc -l 2>/dev/null || echo "0")" -eq 1 ]]; then
    print_warning "Python $PYTHON_VER może być za stary (zalecane 3.8+)"
fi

# Check if pip is available
if ! $PYTHON_CMD -m pip --version &> /dev/null; then
    print_error "pip nie jest dostępny!"
    echo ""
    echo "🔧 Instalacja pip:"
    echo "   $PKG_INSTALL python3-pip"
    echo ""
    exit 1
fi

PIP_VERSION=$($PYTHON_CMD -m pip --version | cut -d' ' -f2)
print_status "pip $PIP_VERSION"

# Check if venv module is available
if ! $PYTHON_CMD -m venv --help &> /dev/null; then
    print_warning "Moduł venv nie jest dostępny, instaluję..."
    if [[ "$PKG_MGR" == "apt" ]]; then
        sudo apt install -y python3-venv
    else
        print_error "Zainstaluj python3-venv ręcznie"
        exit 1
    fi
fi
print_status "venv module dostępny"

echo ""

print_step "[3/6] Sprawdzanie struktury projektu..."
echo ""

if [[ ! -f "package.json" ]]; then
    print_error "Brak pliku package.json! Upewnij się, że jesteś w głównym folderze projektu."
    exit 1
fi
print_status "package.json znaleziony"

if [[ ! -d "backend" ]]; then
    print_error "Folder backend nie istnieje!"
    exit 1
fi
print_status "Folder backend istnieje"

if [[ ! -f "backend/requirements.txt" ]]; then
    print_error "Brak pliku backend/requirements.txt!"
    exit 1
fi
print_status "backend/requirements.txt znaleziony"

echo ""

print_step "[4/6] Instalowanie zależności frontend..."
echo ""

print_status "Instalowanie pakietów npm... (może potrwać kilka minut)"
if npm install --no-audit --prefer-offline; then
    print_status "Zależności frontend zainstalowane pomyślnie"
else
    print_warning "Pierwsza próba nie udała się, próbuję alternatywne metody..."
    npm cache clean --force
    rm -rf node_modules package-lock.json 2>/dev/null || true
    if npm install; then
        print_status "Zależności frontend zainstalowane pomyślnie (druga próba)"
    else
        print_error "Nie udało się zainstalować zależności frontend"
        echo ""
        echo "� Spróbuj ręcznie:"
        echo "   npm cache clean --force"
        echo "   rm -rf node_modules package-lock.json"
        echo "   npm install --legacy-peer-deps"
        exit 1
    fi
fi

echo ""

print_step "[5/6] Konfiguracja backendu Python..."
echo ""

cd backend

# Create virtual environment if it doesn't exist
if [[ ! -d "venv" ]]; then
    print_status "Tworzenie środowiska wirtualnego Python..."
    if $PYTHON_CMD -m venv venv --prompt "NBA-Analytics"; then
        print_status "Środowisko wirtualne utworzone pomyślnie"
    else
        print_error "Nie udało się utworzyć środowiska wirtualnego"
        echo ""
        echo "💡 Spróbuj ręcznie:"
        echo "   $PKG_INSTALL python3-venv"
        echo "   $PYTHON_CMD -m venv venv"
        exit 1
    fi
else
    print_status "Środowisko wirtualne już istnieje"
fi

# Activate virtual environment and install dependencies
print_status "Aktywuję środowisko wirtualne..."
source venv/bin/activate

print_status "Aktualizuję pip..."
python -m pip install --upgrade pip --quiet

print_status "Instaluję zależności Python... (może potrwać kilka minut)"
if pip install -r requirements.txt --no-warn-script-location; then
    print_status "Zależności Python zainstalowane pomyślnie"
else
    print_error "Nie udało się zainstalować zależności Python"
    echo ""
    echo "💡 Spróbuj ręcznie:"
    echo "   cd backend"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt -v"
    exit 1
fi

# Test key imports
print_status "Testowanie importów kluczowych modułów..."
python -c "import fastapi; print('✓ FastAPI')" 2>/dev/null || print_warning "FastAPI import problem"
python -c "import uvicorn; print('✓ Uvicorn')" 2>/dev/null || print_warning "Uvicorn import problem"  
python -c "import supabase; print('✓ Supabase')" 2>/dev/null || print_warning "Supabase import problem"

cd ..

echo ""

print_step "[6/6] Tworzenie plików konfiguracyjnych..."
echo ""

# Create .env if it doesn't exist
if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
        cp .env.example .env
        print_status "Plik .env utworzony z szablonu .env.example"
    else
        cat > .env << 'EOF'
# NBA Analytics - Environment Configuration
VITE_API_BASE_URL=http://localhost:8000
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
VITE_ODDS_API_KEY=your_odds_api_key_here
VITE_APP_TIMEZONE=America/Chicago
VITE_REFRESH_INTERVAL=30000
EOF
        print_status "Podstawowy plik .env utworzony"
    fi
    print_warning "WAŻNE: Uzupełnij plik .env swoimi kluczami API!"
else
    print_status "Plik .env już istnieje"
fi

# Create backend .env if missing
if [[ ! -f "backend/.env" ]]; then
    cat > backend/.env << 'EOF'
# Backend Environment Configuration
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
ODDS_API_KEY=your_odds_api_key_here
EOF
    print_status "Backend .env utworzony"
fi

echo ""
echo "================================================"
echo "🎉 INSTALACJA ZAKOŃCZONA POMYŚLNIE!"
echo "================================================"
echo ""
echo "📋 NASTĘPNE KROKI:"
echo ""
echo "1️⃣  SKONFIGURUJ KLUCZE API w pliku .env:"
echo "   📝 Edytuj: nano .env"
echo "   🌐 Supabase: https://supabase.com/"
echo "   🎲 The Odds API: https://the-odds-api.com/"
echo ""
echo "2️⃣  URUCHOM APLIKACJĘ (2 terminale):"
echo "   🔧 Backend:  cd backend && source venv/bin/activate && python main.py"
echo "   🎨 Frontend: npm run dev"
echo ""
echo "3️⃣  DOSTĘP DO APLIKACJI:"
echo "   🌐 Frontend: http://localhost:5173"
echo "   🔌 API: http://localhost:8000/docs"
echo ""
echo "📖 DOKUMENTACJA:"
echo "   � README.md - Pełna dokumentacja"
echo "   🚀 QUICKSTART.md - Szybki start"
echo ""
echo "🏀 POWODZENIA W ANALIZIE NBA! 🚀"
echo "================================================"