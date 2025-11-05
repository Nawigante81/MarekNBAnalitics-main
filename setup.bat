@echo off
chcp 65001 >nul 2>&1
echo ================================================
echo 🏀 NBA Analysis ^& Betting System - Windows Setup
echo ================================================
echo.

echo [1/6] Sprawdzanie wymagań systemowych...
echo.

REM Check Windows version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo 💻 System: Windows %VERSION%

REM Check if running as Administrator (optional)
net session >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Uwaga: Uruchamiasz jako Administrator - nie jest to wymagane
)
echo.

REM Check if Node.js is installed
echo Sprawdzanie Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js nie jest zainstalowany!
    echo.
    echo 📥 Pobierz i zainstaluj Node.js LTS z:
    echo    https://nodejs.org/
    echo.
    echo ⚠️  Po instalacji zrestartuj terminal i uruchom ponownie setup.bat
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo ✅ Node.js %NODE_VERSION% jest zainstalowany
echo.

REM Check if npm is available
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm nie jest dostępny!
    echo.
    echo Zainstaluj ponownie Node.js z https://nodejs.org/
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo ✅ npm %NPM_VERSION% jest dostępny
echo.

REM Check if Python is installed
echo Sprawdzanie Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python nie jest zainstalowany lub nie jest w PATH!
    echo.
    echo 📥 Pobierz i zainstaluj Python 3.11+ z:
    echo    https://www.python.org/downloads/
    echo.
    echo ⚠️  WAŻNE: Podczas instalacji ZAZNACZ:
    echo    ☑️ "Add Python to PATH"
    echo    ☑️ "Install for all users" (opcjonalne)
    echo.
    echo Po instalacji zrestartuj terminal i uruchom ponownie setup.bat
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ %PYTHON_VERSION% jest zainstalowany
echo.

REM Check if pip is available
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ pip nie jest dostępny!
    echo.
    echo Zainstaluj ponownie Python z opcją pip
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python -m pip --version') do set PIP_VERSION=%%i
echo ✅ pip jest dostępny
echo.

echo ✅ Wszystkie wymagania systemowe spełnione!
echo.

REM Check available disk space
for /f "tokens=3" %%a in ('dir /-c %cd% 2^>nul ^| find "bytes free"') do set FREE_SPACE=%%a
echo 💾 Dostępne miejsce na dysku: %FREE_SPACE% bajtów
echo.

REM Setup Frontend
echo [2/6] Instalowanie zależności frontend (React/Vite)...
echo.
echo 📦 Sprawdzanie package.json...
if not exist "package.json" (
    echo ❌ Brak pliku package.json!
    echo.
    echo Upewnij się, że jesteś w głównym folderze projektu.
    echo.
    pause
    exit /b 1
)
echo ✅ package.json znaleziony

echo.
echo 📦 Instalowanie zależności npm... (może potrwać kilka minut)
echo.
call npm install --no-audit --prefer-offline 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  Pierwsza próba nie udała się, próbuję alternatywne metody...
    echo.
    echo 🧹 Czyszczenie cache npm...
    call npm cache clean --force >nul 2>&1
    echo.
    echo 🗑️  Usuwanie node_modules i package-lock.json...
    if exist "node_modules" rmdir /s /q node_modules >nul 2>&1
    if exist "package-lock.json" del /q package-lock.json >nul 2>&1
    echo.
    echo 🔄 Ponowna instalacja...
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ Błąd podczas instalacji zależności frontend
        echo.
        echo 💡 Możliwe rozwiązania:
        echo    1. Sprawdź połączenie internetowe
        echo    2. Uruchom jako Administrator
        echo    3. Zainstaluj ponownie Node.js
        echo    4. Spróbuj: npm install --legacy-peer-deps
        echo.
        pause
        exit /b 1
    )
)
echo ✅ Zależności frontend zainstalowane pomyślnie
echo.

REM Setup Backend
echo [3/6] Konfiguracja backendu Python...
echo.
if not exist "backend" (
    echo ❌ Folder backend nie istnieje!
    echo.
    echo Upewnij się, że jesteś w głównym folderze projektu.
    echo.
    pause
    exit /b 1
)
cd backend

echo 📦 Sprawdzanie requirements.txt...
if not exist "requirements.txt" (
    echo ❌ Brak pliku requirements.txt w folderze backend!
    echo.
    cd ..
    pause
    exit /b 1
)
echo ✅ requirements.txt znaleziony

REM Create virtual environment if it doesn't exist  
if not exist "venv" (
    echo.
    echo 🔧 Tworzenie środowiska wirtualnego Python...
    echo    (Może potrwać kilka minut przy pierwszym uruchomieniu)
    echo.
    python -m venv venv --prompt "NBA-Analytics"
    if %errorlevel% neq 0 (
        echo ❌ Błąd podczas tworzenia venv
        echo.
        echo 💡 Możliwe przyczyny:
        echo    1. Python nie ma uprawnień do zapisu
        echo    2. Błąd instalacji Python
        echo    3. Brak modułu venv
        echo.
        echo 🔧 Spróbuj ręcznie:
        echo    python -m pip install --upgrade pip
        echo    python -m pip install virtualenv
        echo    python -m virtualenv venv
        echo.
        cd ..
        pause
        exit /b 1
    )
    echo ✅ Środowisko wirtualne utworzone pomyślnie
) else (
    echo ℹ️  Środowisko wirtualne już istnieje - pomijam tworzenie
)
echo.

REM Test virtual environment activation
echo 🧪 Testowanie aktywacji środowiska wirtualnego...
if not exist "venv\Scripts\activate.bat" (
    echo ❌ Plik aktywacji venv nie istnieje!
    echo.
    echo Usuwam uszkodzone venv i tworzę ponownie...
    rmdir /s /q venv >nul 2>&1
    python -m venv venv --prompt "NBA-Analytics"
    if %errorlevel% neq 0 (
        echo ❌ Nie udało się ponownie utworzyć venv
        cd ..
        pause
        exit /b 1
    )
)
echo ✅ Środowisko wirtualne jest funkcjonalne

REM Activate virtual environment and install dependencies
echo.
echo [4/6] Instalowanie zależności Python...
echo.
echo 🔄 Aktywuję środowisko wirtualne...
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ Nie udało się aktywować środowiska wirtualnego
    cd ..
    pause
    exit /b 1
)

echo 📦 Aktualizuję pip w środowisku wirtualnym...
python -m pip install --upgrade pip --quiet
if %errorlevel% neq 0 (
    echo ⚠️  Ostrzeżenie: Nie udało się zaktualizować pip, kontynuuję...
)

echo 📦 Instaluję zależności Python... (może potrwać kilka minut)
echo.
pip install -r requirements.txt --no-warn-script-location
if %errorlevel% neq 0 (
    echo ❌ Błąd podczas instalacji zależności Python
    echo.
    echo 💡 Możliwe rozwiązania:
    echo    1. Sprawdź połączenie internetowe
    echo    2. Uruchom jako Administrator
    echo    3. Spróbuj: pip install -r requirements.txt --user
    echo    4. Zaktualizuj Python do najnowszej wersji
    echo.
    echo 🔧 Aby debugować:
    echo    cd backend
    echo    venv\Scripts\activate
    echo    pip install -r requirements.txt -v
    echo.
    cd ..
    pause
    exit /b 1
)
echo ✅ Wszystkie zależności Python zainstalowane pomyślnie
echo.

echo 🧪 Testowanie importów kluczowych modułów...
python -c "import fastapi; print('✓ FastAPI')" 2>nul || echo "⚠️ FastAPI import problem"
python -c "import uvicorn; print('✓ Uvicorn')" 2>nul || echo "⚠️ Uvicorn import problem"
python -c "import supabase; print('✓ Supabase')" 2>nul || echo "⚠️ Supabase import problem"
echo.

cd ..


echo [5/6] Sprawdzanie i tworzenie plików konfiguracyjnych...
echo.

REM Check if .env file exists
if not exist ".env" (
    echo ⚠️  Plik .env nie istnieje!
    echo.
    if exist ".env.example" (
        echo 📄 Tworzenie .env z .env.example...
        copy .env.example .env >nul
        echo ✅ Plik .env utworzony z szablonu
        echo.
        echo ⚠️  WAŻNE: Musisz uzupełnić plik .env swoimi kluczami API!
    ) else (
        echo ⚠️  Brak pliku .env.example - tworzę podstawowy .env...
        echo # NBA Analytics - Environment Configuration > .env
        echo VITE_API_BASE_URL=http://localhost:8000 >> .env
        echo VITE_SUPABASE_URL=your_supabase_url_here >> .env
        echo VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here >> .env
        echo VITE_ODDS_API_KEY=your_odds_api_key_here >> .env
        echo VITE_APP_TIMEZONE=America/Chicago >> .env
        echo VITE_REFRESH_INTERVAL=30000 >> .env
        echo ✅ Podstawowy plik .env utworzony
    )
) else (
    echo ✅ Plik .env już istnieje
)

REM Create backend .env if missing
if not exist "backend\.env" (
    echo 📄 Tworzenie backend\.env...
    echo # Backend Environment Configuration > backend\.env
    echo VITE_SUPABASE_URL=your_supabase_url_here >> backend\.env
    echo VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here >> backend\.env
    echo ODDS_API_KEY=your_odds_api_key_here >> backend\.env
    echo ✅ Backend .env utworzony
)

REM Final validation
echo.
echo [6/6] Sprawdzanie finalnej konfiguracji...
echo.

echo 🔍 Sprawdzanie struktury projektu...
if exist "package.json" echo ✅ Frontend: package.json
if exist "src" echo ✅ Frontend: src/ folder
if exist "backend\main.py" echo ✅ Backend: main.py
if exist "backend\requirements.txt" echo ✅ Backend: requirements.txt  
if exist "backend\venv" echo ✅ Backend: venv środowisko
if exist ".env" echo ✅ Konfiguracja: .env
echo.

echo 🧪 Test szybkiego uruchomienia...
echo    Frontend ready: npm run dev
echo    Backend ready: cd backend ^&^& venv\Scripts\activate ^&^& python main.py
echo.

echo ================================================
echo 🎉 INSTALACJA ZAKOŃCZONA POMYŚLNIE!
echo ================================================
echo.
echo 📋 NASTĘPNE KROKI:
echo.
echo 1️⃣  SKONFIGURUJ KLUCZE API w pliku .env:
echo     📝 Edytuj: .env
echo     🌐 Supabase: https://supabase.com/
echo        ├─ VITE_SUPABASE_URL=https://xxx.supabase.co
echo        └─ VITE_SUPABASE_ANON_KEY=eyJ...
echo     🎲 The Odds API: https://the-odds-api.com/
echo        └─ VITE_ODDS_API_KEY=xxx...
echo.
echo 2️⃣  URUCHOM APLIKACJĘ:
echo     🚀 Automatycznie: start.bat
echo     🐳 Docker: docker-start.bat (wymaga Docker Desktop)
echo     📖 Ręcznie: Zobacz instrukcje poniżej
echo.
echo 3️⃣  RĘCZNE URUCHOMIENIE (2 terminale):
echo     🔧 Backend: cd backend ^&^& venv\Scripts\activate ^&^& python main.py
echo     🎨 Frontend: npm run dev
echo.
echo 4️⃣  DOSTĘP DO APLIKACJI:
echo     🌐 Frontend: http://localhost:5173
echo     🔌 API: http://localhost:8000
echo     📚 API Docs: http://localhost:8000/docs
echo.
echo 📖 DOKUMENTACJA:
echo     📋 Szybki start: QUICKSTART_WINDOWS.md
echo     🔧 Szczegóły: WINDOWS_SETUP.md  
echo     🆘 Problemy: TROUBLESHOOTING_VENV.md
echo.
echo 🏀 POWODZENIA W ANALIZIE NBA! 🚀
echo ================================================
echo.
echo Naciśnij dowolny klawisz aby zakończyć...
pause >nul
