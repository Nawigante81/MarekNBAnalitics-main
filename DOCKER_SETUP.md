# 🐳 Uruchomienie projektu NBA Analytics w Docker

**TAK!** Projekt ma pełne wsparcie Docker i można go uruchomić w kontenerach na Windows 11.

---

## 🏗️ Architektura Docker

Projekt składa się z 3 kontenerów:

| Kontener | Opis | Port | Technologia |
|----------|------|------|-------------|
| **nba-backend** | FastAPI + Python | 8000 | Python 3.11-slim |
| **nba-frontend** | React + Nginx | 80/443 | Node.js 18 + Nginx |
| **nba-redis** | Cache (opcjonalny) | 6379 | Redis 7-alpine |

---

## 📋 Wymagania

### 1. Zainstaluj Docker Desktop
- Pobierz: https://www.docker.com/products/docker-desktop/
- Zainstaluj Docker Desktop for Windows
- Uruchom Docker Desktop
- Sprawdź: `docker --version` i `docker-compose --version`

### 2. Skonfiguruj zmienne środowiskowe
Uzupełnij plik `.env.production` (już istnieje w projekcie):

```env
# Supabase - UZUPEŁNIJ SWOJE KLUCZE!
VITE_SUPABASE_URL=https://twoj-projekt.supabase.co
VITE_SUPABASE_ANON_KEY=twoj_anon_key
SUPABASE_SERVICE_KEY=twoj_service_key

# The Odds API - UZUPEŁNIJ SWÓJ KLUCZ!
ODDS_API_KEY=twoj_odds_api_key

# Pozostałe (zostaw jak jest)
NODE_ENV=production
HOST=0.0.0.0
PORT=8000
TZ=America/Chicago
```

---

## 🚀 Metody uruchomienia

### Metoda 1: Docker Compose (ZALECANA) ⭐

**Kompletna aplikacja (backend + frontend + redis):**
```powershell
# W głównym folderze projektu
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main

# Uruchom wszystkie kontenery
docker-compose up -d

# Sprawdź status
docker-compose ps

# Zobacz logi
docker-compose logs -f
```

**Dostęp:**
- 🎨 Frontend: http://localhost
- 🔌 Backend API: http://localhost:8000
- 📚 API Docs: http://localhost:8000/docs
- 🔍 Redis (opcjonalny): localhost:6379

---

### Metoda 2: Tylko backend (szybko)

```powershell
# Zbuduj backend
cd backend
docker build -t nba-backend .

# Uruchom backend (z plikiem .env)
docker run -d \
  --name nba-backend \
  -p 8000:8000 \
  --env-file ../.env.production \
  nba-backend

# Sprawdź logi
docker logs -f nba-backend
```

**Dostęp:**
- 🔌 Backend: http://localhost:8000
- 📚 Docs: http://localhost:8000/docs

---

### Metoda 3: Tylko frontend

```powershell
# Zbuduj frontend
docker build -t nba-frontend -f Dockerfile .

# Uruchom frontend
docker run -d \
  --name nba-frontend \
  -p 80:80 \
  nba-frontend

# Sprawdź
curl http://localhost
```

---

## 🔧 Dostępne docker-compose pliki

| Plik | Opis | Kiedy użyć |
|------|------|------------|
| `docker-compose.yml` | Standardowy (backend + frontend + redis) | ✅ Większość przypadków |
| `docker-compose-caddy.yml` | Z Caddy reverse proxy + SSL | Produkcja z HTTPS |
| `docker-compose.pi4.yml` | Wersja dla Raspberry Pi 4 | ARM64 devices |

---

## 🛠️ Przydatne komendy Docker

### Podstawowe operacje:
```powershell
# Uruchom w tle
docker-compose up -d

# Zatrzymaj
docker-compose down

# Restart
docker-compose restart

# Zobacz status
docker-compose ps

# Zobacz logi (wszystkie kontenery)
docker-compose logs -f

# Zobacz logi konkretnego kontenera
docker-compose logs -f backend
```

### Zarządzanie obrazami:
```powershell
# Zbuduj od nowa (force rebuild)
docker-compose build --no-cache

# Usuń stare obrazy
docker system prune -a

# Zobacz używane miejsce
docker system df
```

### Debugging:
```powershell
# Wejdź do kontenera backend
docker-compose exec backend bash

# Wejdź do kontenera frontend
docker-compose exec frontend sh

# Sprawdź zmienne środowiskowe
docker-compose exec backend env

# Sprawdź procesy w kontenerze
docker-compose exec backend ps aux
```

---

## 🔍 Monitoring i diagnostyka

### Health checks:
Wszystkie kontenery mają wbudowane health checki:

```powershell
# Sprawdź zdrowie kontenerów
docker-compose ps

# Powinno pokazać "Up (healthy)" dla każdego kontenera
```

### Logi aplikacji:
```powershell
# Backend logi (FastAPI + NBA data scraping)
docker-compose logs -f backend

# Frontend logi (Nginx)
docker-compose logs -f frontend

# Redis logi (cache operations)
docker-compose logs -f redis
```

### Metryki zasobów:
```powershell
# Użycie CPU/RAM przez kontenery
docker stats

# Szczegółowe info o kontenerze
docker inspect nba-backend
```

---

## 📦 Volumes i persystencja danych

### Dane przechowywane:
- ✅ **Redis data**: `/data` (volume: `redis_data`)
- ✅ **Backend logs**: `./backend/logs` (bind mount)
- ✅ **SSL certificates**: `./ssl` (bind mount, opcjonalny)

### Backup Redis:
```powershell
# Backup Redis data
docker-compose exec redis redis-cli BGSAVE

# Copy backup
docker cp nba-redis:/data/dump.rdb ./redis-backup.rdb
```

---

## 🌐 Konfiguracja sieci

### Network: nba-network
Wszystkie kontenery komunikują się przez dedykowaną sieć Docker:

```
Frontend (nginx:80) 
    ↓ proxy_pass
Backend (fastapi:8000)
    ↓ cache
Redis (redis:6379)
```

### Komunikacja:
- Frontend → Backend: `http://backend:8000`
- Backend → Redis: `redis://redis:6379`
- Host → Frontend: `http://localhost`
- Host → Backend: `http://localhost:8000`

---

## ⚡ Optymalizacje produkcyjne

### Multi-stage builds:
- ✅ Frontend: Node.js build → Nginx serve
- ✅ Backend: Python optimized image
- ✅ Minimalne obrazy (Alpine Linux)

### Bezpieczeństwo:
- ✅ Non-root users w kontenerach
- ✅ Security headers (nginx)
- ✅ Izolowana sieć Docker
- ✅ Health checks

### Performance:
- ✅ Gzip compression (nginx)
- ✅ Static file caching
- ✅ Redis caching
- ✅ Connection pooling

---

## 🔄 CI/CD i deployment

### GitHub Actions (przykład):
```yaml
name: Build and Deploy
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and deploy
        run: |
          docker-compose build
          docker-compose up -d
```

### Production deployment:
```powershell
# Produkcja z SSL (Caddy)
docker-compose -f docker-compose-caddy.yml up -d

# Sprawdź SSL
curl -I https://twoja-domena.com
```

---

## 📊 Porównanie: Docker vs Native

| Aspekt | Native (setup.bat) | Docker |
|--------|-------------------|---------|
| **Szybkość setup** | 🟡 10 minut | 🟢 5 minut |
| **Zależności** | 🟡 Node.js + Python | 🟢 Tylko Docker |
| **Izolacja** | 🟡 venv | 🟢 Pełna izolacja |
| **Przenośność** | 🔴 Tylko Windows | 🟢 Wszędzie |
| **Debugging** | 🟢 Łatwe | 🟡 Średnie |
| **Produkcja** | 🟡 Wymaga konfiguracji | 🟢 Gotowe |
| **Zasoby** | 🟢 Minimalne | 🟡 Więcej RAM |

---

## 🚨 Troubleshooting

### Port jest zajęty:
```powershell
# Sprawdź co używa portu 80
netstat -ano | findstr :80

# Zmień port w docker-compose.yml
ports:
  - "8080:80"  # Użyj portu 8080 zamiast 80
```

### Brak pamięci:
```powershell
# Zwiększ pamięć dla Docker Desktop
# Settings → Resources → Advanced → Memory: 4GB+
```

### Błędy budowania:
```powershell
# Wyczyść Docker cache
docker system prune -a --volumes

# Zbuduj od nowa
docker-compose build --no-cache
```

### Kontenery nie startują:
```powershell
# Sprawdź logi
docker-compose logs

# Sprawdź health checks
docker-compose ps

# Restart problematycznego kontenera
docker-compose restart backend
```

---

## ✅ Podsumowanie

### Zalety Docker:
- ✅ **Szybki setup** - jedna komenda
- ✅ **Nie trzeba instalować** Node.js/Python
- ✅ **Pełna izolacja** - nie zamula systemu
- ✅ **Identyczne środowisko** - dev = prod
- ✅ **Łatwy deployment** - gdzie Docker, tam działa
- ✅ **Skalowalność** - łatwo dodać więcej instancji

### Kiedy użyć Docker:
- 🟢 Szybki test projektu
- 🟢 Deployment na serwer
- 🟢 Nie chcesz instalować zależności
- 🟢 Praca zespołowa (identyczne środowiska)
- 🟢 CI/CD pipeline

### Kiedy użyć Native:
- 🟢 Development i debugging
- 🟢 Uczenie się projektu
- 🟢 Modyfikacje kodu
- 🟢 Słabszy sprzęt (mniej RAM)

---

## 🚀 Quick Start - Docker (3 komendy)

```powershell
# 1. Sklonuj/pobierz projekt
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main

# 2. Uzupełnij .env.production (klucze Supabase + Odds API)

# 3. Uruchom!
docker-compose up -d

# 4. Otwórz przeglądarkę
start http://localhost
```

**Gotowe! 🎉**

---

**Docker setup dostępny i gotowy do użycia!** Projekt będzie działać w izolowanych kontenerach bez potrzeby instalowania Node.js czy Python na Twoim systemie.