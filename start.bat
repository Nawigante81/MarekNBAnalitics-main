@echo off
chcp 65001 >nul 2>&1
echo ================================================
echo 🏀 NBA Analysis System - Quick Start
echo ================================================
echo.

echo 🔍 Sprawdzanie gotowości projektu...
echo.

REM Check if we are in the right directory
if not exist "package.json" (
    echo ❌ Nie jesteś w głównym folderze projektu!
    echo.
    echo Upewnij się, że jesteś w folderze z plikiem package.json
    echo.
    pause
    exit /b 1
)

REM Check if setup was run
if not exist "backend\venv" (
    echo ❌ Środowisko Python nie zostało utworzone!
    echo.
    echo 🔧 Uruchom najpierw: setup.bat
    echo.
    pause
    exit /b 1
)

if not exist "node_modules" (
    echo ❌ Zależności frontend nie zostały zainstalowane!
    echo.
    echo 🔧 Uruchom najpierw: setup.bat
    echo.
    pause
    exit /b 1
)

if not exist ".env" (
    echo ❌ Plik .env nie istnieje!
    echo.
    echo 🔧 Rozwiązania:
    echo    1. Uruchom: setup.bat (automatyczne tworzenie)
    echo    2. Skopiuj .env.example do .env ręcznie
    echo    3. Uzupełnij klucze API w pliku .env
    echo.
    pause
    exit /b 1
)

REM Check if .env has required keys
findstr /C:"your_supabase_url_here" .env >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Plik .env zawiera przykładowe wartości!
    echo.
    echo 🔑 Musisz uzupełnić prawdziwe klucze API:
    echo    - VITE_SUPABASE_URL
    echo    - VITE_SUPABASE_ANON_KEY  
    echo    - VITE_ODDS_API_KEY
    echo.
    echo 📖 Zobacz: QUICKSTART_WINDOWS.md - sekcja "Wymagane klucze API"
    echo.
    choice /C YN /M "Kontynuować mimo to?"
    if !errorlevel! equ 2 exit /b 0
    echo.
)

REM Check if backend main.py exists
if not exist "backend\main.py" (
    echo ❌ Brak pliku backend\main.py!
    echo.
    echo Sprawdź strukturę projektu
    echo.
    pause
    exit /b 1
)

REM Check port availability
netstat -an | findstr :8000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Port 8000 jest zajęty!
    echo.
    choice /C YN /M "Zabić procesy na porcie 8000?"
    if !errorlevel! equ 1 (
        for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8000') do taskkill /pid %%i /f >nul 2>&1
        echo ✅ Procesy na porcie 8000 zakończone
    )
)

netstat -an | findstr :5173 >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Port 5173 jest zajęty!
    echo.
    choice /C YN /M "Zabić procesy na porcie 5173?"
    if !errorlevel! equ 1 (
        for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5173') do taskkill /pid %%i /f >nul 2>&1
        echo ✅ Procesy na porcie 5173 zakończone
    )
)

echo ✅ Wszystko gotowe! Uruchamiam aplikację...
echo.
echo 📋 Otworzy się 2 okna terminala:
echo    1️⃣  Backend (Python/FastAPI) - port 8000
echo    2️⃣  Frontend (React/Vite) - port 5173
echo.
echo ⚠️  WAŻNE: Nie zamykaj tych okien podczas korzystania z aplikacji!
echo.
echo 🌐 Po uruchomieniu aplikacja będzie dostępna na:
echo    Frontend: http://localhost:5173
echo    API: http://localhost:8000/docs
echo.
pause

REM Start backend in new window
echo 🚀 Uruchamiam backend...
start "🏀 NBA Backend (FastAPI)" cmd /k "echo 🐍 Uruchamiam backend NBA Analytics... && cd backend && venv\Scripts\activate && echo ✅ Środowisko wirtualne aktywowane && python main.py"

echo    ⏳ Czekam 4 sekundy na uruchomienie backendu...
timeout /t 4 /nobreak >nul

echo 🚀 Uruchamiam frontend...
start "🎨 NBA Frontend (React)" cmd /k "echo ⚛️ Uruchamiam frontend NBA Analytics... && npm run dev"

echo.
echo ✅ APLIKACJA URUCHOMIONA POMYŚLNIE!
echo.
echo 🌐 DOSTĘP DO APLIKACJI:
echo    📱 Frontend:  http://localhost:5173
echo    🔌 API:       http://localhost:8000  
echo    📚 API Docs:  http://localhost:8000/docs
echo    💾 Health:    http://localhost:8000/health
echo.
echo ⏸️  ZATRZYMANIE:
echo    - Zamknij oba okna terminala (Backend i Frontend)
echo    - Lub użyj: stop.bat
echo.
echo 🎯 FUNKCJE DOSTĘPNE:
echo    📊 Dashboard NBA z analizami
echo    🏀 Chicago Bulls - analiza graczy
echo    💰 Rekomendacje zakładów (Kelly Criterion)
echo    📈 Raporty automatyczne (7:50, 8:00, 11:00)
echo    🎲 Live odds monitoring
echo.
echo 🚀 OTWIERANIE W PRZEGLĄDARCE...
timeout /t 2 /nobreak >nul
start http://localhost:5173
echo.
echo ✨ Miłej analizy NBA! 🏀
pause >nul
