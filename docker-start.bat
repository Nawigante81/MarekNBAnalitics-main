@echo off
chcp 65001 >nul 2>&1
echo ================================================
echo 🐳 NBA Analytics - Docker Production Setup
echo ================================================
echo.

echo 🔍 Sprawdzanie wymagań Docker...
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker nie jest zainstalowany!
    echo.
    echo 📥 Pobierz i zainstaluj Docker Desktop z:
    echo    https://www.docker.com/products/docker-desktop/
    echo.
    echo 📋 Wymagania:
    echo    - Windows 10 Pro/Enterprise lub Windows 11
    echo    - Włączone WSL 2 lub Hyper-V
    echo    - Minimum 4GB RAM
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('docker --version') do set DOCKER_VERSION=%%i
echo ✅ %DOCKER_VERSION%

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Docker Compose nie jest dostępny, sprawdzam docker compose...
    docker compose version >nul 2>&1
    if !errorlevel! neq 0 (
        echo ❌ Docker Compose nie jest dostępny!
        echo.
        echo Zainstaluj najnowszą wersję Docker Desktop
        echo.
        pause
        exit /b 1
    ) else (
        set COMPOSE_CMD=docker compose
        for /f "tokens=*" %%i in ('docker compose version') do echo ✅ %%i
    )
) else (
    set COMPOSE_CMD=docker-compose
    for /f "tokens=*" %%i in ('docker-compose --version') do echo ✅ %%i
)

REM Check if Docker daemon is running
echo 🔍 Sprawdzanie czy Docker daemon działa...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker daemon nie jest uruchomiony!
    echo.
    echo 🔧 Rozwiązania:
    echo    1. Uruchom Docker Desktop
    echo    2. Zaczekaj aż Docker się załaduje (może potrwać 1-2 minuty)
    echo    3. Sprawdź czy Docker Desktop działa w system tray
    echo.
    choice /C YN /M "Spróbować uruchomić Docker Desktop automatycznie?"
    if !errorlevel! equ 1 (
        echo 🚀 Próbuję uruchomić Docker Desktop...
        start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" >nul 2>&1
        echo ⏳ Czekam 30 sekund na uruchomienie...
        timeout /t 30 /nobreak >nul
        docker ps >nul 2>&1
        if !errorlevel! neq 0 (
            echo ❌ Docker nadal nie działa. Uruchom Docker Desktop ręcznie.
            pause
            exit /b 1
        )
        echo ✅ Docker uruchomiony pomyślnie!
    ) else (
        echo Uruchom Docker Desktop i spróbuj ponownie.
        pause
        exit /b 1
    )
) else (
    echo ✅ Docker daemon działa
)
echo.

REM Check configuration files
echo 🔍 Sprawdzanie plików konfiguracyjnych...

if not exist "docker-compose.yml" (
    echo ❌ Brak pliku docker-compose.yml!
    echo.
    echo Upewnij się, że jesteś w głównym folderze projektu.
    echo.
    pause
    exit /b 1
)
echo ✅ docker-compose.yml znaleziony

REM Check for environment file
if not exist ".env.production" (
    echo ⚠️  Plik .env.production nie istnieje!
    echo.
    if exist ".env" (
        echo 📄 Kopiuję .env do .env.production...
        copy .env .env.production >nul
        echo ✅ Skopiowano .env do .env.production
    ) else if exist ".env.example" (
        echo 📄 Tworzę .env.production z .env.example...
        copy .env.example .env.production >nul
        echo ✅ Utworzono .env.production z szablonu
        echo.
        echo ⚠️  UWAGA: Uzupełnij klucze API w .env.production!
    ) else (
        echo 📄 Tworzę podstawowy .env.production...
        echo # NBA Analytics - Production Environment > .env.production
        echo VITE_API_BASE_URL=http://localhost:8000 >> .env.production
        echo VITE_SUPABASE_URL=your_supabase_url_here >> .env.production
        echo VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here >> .env.production
        echo VITE_ODDS_API_KEY=your_odds_api_key_here >> .env.production
        echo VITE_APP_TIMEZONE=America/Chicago >> .env.production
        echo ✅ Utworzono podstawowy .env.production
    )
    echo.
    echo 🔑 Wymagane klucze API w .env.production:
    echo    - VITE_SUPABASE_URL (z https://supabase.com/)
    echo    - VITE_SUPABASE_ANON_KEY
    echo    - VITE_ODDS_API_KEY (z https://the-odds-api.com/)
    echo.
) else (
    echo ✅ Plik .env.production istnieje
)

REM Check for example keys
findstr /C:"your_supabase_url_here" .env.production >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  UWAGA: .env.production zawiera przykładowe klucze!
    echo.
    choice /C YN /M "Kontynuować z przykładowymi kluczami (aplikacja może nie działać)?"
    if !errorlevel! equ 2 (
        echo.
        echo 📝 Edytuj plik .env.production i uruchom ponownie
        pause
        exit /b 0
    )
)

REM Check available ports
echo.
echo 🔍 Sprawdzanie dostępności portów...
netstat -an | findstr :80 >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Port 80 jest zajęty! (Frontend)
    choice /C YN /M "Kontynuować mimo to?"
    if !errorlevel! equ 2 exit /b 0
)

netstat -an | findstr :8000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Port 8000 jest zajęty! (Backend)
    choice /C YN /M "Kontynuować mimo to?"
    if !errorlevel! equ 2 exit /b 0
)

echo ✅ Porty dostępne
echo.

echo 🔧 Uruchamiam aplikację w Docker...
echo.
echo ⏳ Może potrwać kilka minut przy pierwszym uruchomieniu:
echo    1. Docker pobiera obrazy bazowe (Python, Node, Redis)
echo    2. Buduje obraz backendu (instaluje pip packages)
echo    3. Buduje obraz frontendu (npm install + build)
echo    4. Uruchamia wszystkie serwisy
echo.
choice /C YN /M "Kontynuować uruchomienie Docker?"
if !errorlevel! equ 2 exit /b 0

echo.
echo 📦 Budowanie i uruchamianie kontenerów...
echo    (Możesz monitorować postęp w Docker Desktop)
echo.

REM Start Docker Compose with better error handling
%COMPOSE_CMD% up -d --build

if %errorlevel% neq 0 (
    echo ❌ Błąd podczas uruchamiania Docker Compose
    echo.
    echo 🔍 Diagnoza problemu:
    %COMPOSE_CMD% ps
    echo.
    echo 📋 Sprawdź logi:
    echo    %COMPOSE_CMD% logs backend
    echo    %COMPOSE_CMD% logs frontend  
    echo    %COMPOSE_CMD% logs --tail=50
    echo.
    choice /C YN /M "Wyświetlić logi teraz?"
    if !errorlevel! equ 1 (
        echo.
        echo === LOGI BACKEND ===
        %COMPOSE_CMD% logs backend
        echo.
        echo === LOGI FRONTEND ===
        %COMPOSE_CMD% logs frontend
    )
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ DOCKER KONTENERERY URUCHOMIONE POMYŚLNIE!
echo.

echo ⏳ Sprawdzanie statusu serwisów... 
timeout /t 5 /nobreak >nul

echo.
echo 📊 STATUS KONTENERÓW:
%COMPOSE_CMD% ps

echo.
echo 🌐 DOSTĘP DO APLIKACJI:
echo    🎨 Frontend:    http://localhost
echo    🔌 Backend API: http://localhost:8000  
echo    📚 API Docs:    http://localhost:8000/docs
echo    💾 Health:      http://localhost:8000/health
echo    🗃️  Redis:       localhost:6379
echo.

echo � TESTOWANIE DOSTĘPNOŚCI...
echo Testowanie backend health...
timeout /t 3 >nul
curl -f http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Backend odpowiada
) else (
    echo ⚠️  Backend jeszcze się uruchamia...
)

echo.
echo � PRZYDATNE KOMENDY:
echo    📝 Logi wszystkich serwisów: %COMPOSE_CMD% logs -f
echo    🔍 Logi tylko backend:       %COMPOSE_CMD% logs -f backend
echo    🎨 Logi tylko frontend:      %COMPOSE_CMD% logs -f frontend
echo    📊 Status kontenerów:        %COMPOSE_CMD% ps
echo    � Restart serwisu:          %COMPOSE_CMD% restart backend
echo    🛑 Zatrzymanie:              %COMPOSE_CMD% down
echo    🗑️  Usunięcie z wolumenami:   %COMPOSE_CMD% down -v
echo.

echo 🚀 OTWIERANIE W PRZEGLĄDARCE...
timeout /t 2 >nul
start http://localhost
echo.

choice /C YN /M "Wyświetlić logi aplikacji na żywo?"
if !errorlevel! equ 1 (
    echo.
    echo 📝 Logi na żywo (Ctrl+C aby wyjść):
    %COMPOSE_CMD% logs -f
) else (
    echo.
    echo ✨ Aplikacja działa w tle!
    echo 🔄 Status: %COMPOSE_CMD% ps
    echo 🛑 Stop: %COMPOSE_CMD% down
    echo.
    pause >nul
)