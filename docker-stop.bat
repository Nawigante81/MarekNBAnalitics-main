@echo off
echo ================================================
echo 🐳 NBA Analytics - Docker Stop
echo ================================================
echo.

echo 🛑 Zatrzymywanie kontenerów Docker...
echo.

docker-compose down

if %errorlevel% equ 0 (
    echo ✅ Wszystkie kontenery zatrzymane
) else (
    echo ⚠️  Wystąpił błąd podczas zatrzymywania
)

echo.
echo 📊 Status kontenerów:
docker-compose ps
echo.
echo 💾 Dane w Redis i logach zostały zachowane
echo.
echo 🔄 Aby uruchomić ponownie: docker-start.bat
echo    lub: docker-compose up -d
echo.
pause