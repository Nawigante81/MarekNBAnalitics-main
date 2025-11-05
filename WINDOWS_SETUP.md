# 🏀 Instrukcja uruchomienia na Windows 11

## Wymagania wstępne

### 1. Zainstaluj Node.js
- Pobierz z: https://nodejs.org/
- Zalecana wersja: LTS (Long Term Support)
- Sprawdź instalację: `node --version` (powinno pokazać np. v20.x.x)

### 2. Zainstaluj Python
- Pobierz z: https://www.python.org/downloads/
- Wersja: Python 3.11 lub nowszy
- **WAŻNE**: Zaznacz "Add Python to PATH" podczas instalacji
- Sprawdź instalację: `python --version` (powinno pokazać np. Python 3.11.x)

### 3. Zainstaluj Git (opcjonalnie)
- Pobierz z: https://git-scm.com/download/win
- Potrzebne jeśli klonujesz projekt z GitHuba

### 4. Zdobądź klucze API

#### Supabase:
1. Załóż konto na: https://supabase.com/
2. Stwórz nowy projekt
3. Przejdź do Settings → API
4. Zapisz:
   - `Project URL` (VITE_SUPABASE_URL)
   - `anon/public key` (VITE_SUPABASE_ANON_KEY)
   - `service_role key` (SUPABASE_SERVICE_KEY)

#### The Odds API:
1. Załóż konto na: https://the-odds-api.com/
2. Zapisz swój API key (ODDS_API_KEY)

---

## Instalacja - Metoda 1: Automatyczna (Zalecana)

### Krok 1: Otwórz PowerShell lub Command Prompt
Kliknij prawym na folder projektu → "Otwórz w terminalu" lub wyszukaj "cmd" w menu Start

### Krok 2: Uruchom skrypt instalacyjny
```cmd
setup.bat
```

Ten skrypt automatycznie:
- Sprawdzi wymagania
- Zainstaluje zależności frontend (npm)
- Utworzy środowisko wirtualne Python
- Zainstaluje zależności backend (pip)

### Krok 3: Skonfiguruj zmienne środowiskowe
1. Skopiuj plik przykładowy:
```cmd
copy .env.example .env
```

2. Edytuj plik `.env` w Notatniku lub VS Code i uzupełnij swoje klucze:
```env
# Supabase Configuration
VITE_SUPABASE_URL=https://twoj-projekt.supabase.co
VITE_SUPABASE_ANON_KEY=twoj_anon_key
SUPABASE_SERVICE_KEY=twoj_service_key

# The Odds API
ODDS_API_KEY=twoj_odds_api_key

# Opcjonalne
BASKETBALL_REFERENCE_USER_AGENT=Mozilla/5.0
```

---

## Instalacja - Metoda 2: Manualna

### Frontend:
```cmd
npm install
```

### Backend:
```cmd
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cd ..
```

---

## Uruchomienie projektu

### Opcja A: Uruchomienie tylko frontendu (tryb developerski)
```cmd
npm run dev
```
Frontend będzie dostępny pod: http://localhost:5173

### Opcja B: Uruchomienie backend + frontend

#### Terminal 1 - Backend:
```cmd
cd backend
venv\Scripts\activate
python main.py
```
Backend API będzie dostępne pod: http://localhost:8000

#### Terminal 2 - Frontend:
```cmd
npm run dev
```
Frontend będzie dostępny pod: http://localhost:5173

### Opcja C: Docker (dla zaawansowanych)

**Wymagania**: Docker Desktop for Windows
- Pobierz z: https://www.docker.com/products/docker-desktop/

```cmd
docker-compose up -d
```

---

## Struktura projektu

```
MarekNBAnalitics/
├── backend/                 # FastAPI Backend
│   ├── main.py             # Główny plik aplikacji
│   ├── scrapers.py         # Scrapery danych NBA
│   ├── reports.py          # Generator raportów
│   ├── requirements.txt    # Zależności Python
│   └── venv/               # Środowisko wirtualne (tworzone automatycznie)
├── src/                    # Frontend React + TypeScript
│   ├── components/         # Komponenty UI
│   ├── types/              # Definicje TypeScript
│   └── App.tsx             # Główny komponent
├── supabase/               # Migracje bazy danych
├── package.json            # Zależności Node.js
├── .env                    # Zmienne środowiskowe (NIE commituj!)
└── setup.bat               # Skrypt instalacyjny Windows
```

---

## Automatyczne raporty

System generuje 3 raporty dziennie (strefa czasowa: America/Chicago):
- **7:50 AM** - Analiza poprzedniego dnia
- **8:00 AM** - Podsumowanie poranne
- **11:00 AM** - Scouting meczów dzisiejszych

---

## Rozwiązywanie problemów

### Problem: "python nie jest rozpoznawany jako polecenie"
**Rozwiązanie**: 
1. Zainstaluj ponownie Python z opcją "Add to PATH"
2. Lub dodaj ręcznie do PATH: `C:\Users\TwojeImie\AppData\Local\Programs\Python\Python311`

### Problem: "node nie jest rozpoznawany jako polecenie"
**Rozwiązanie**: 
1. Zainstaluj ponownie Node.js
2. Zrestartuj komputer po instalacji

### Problem: "Cannot find module 'vite'"
**Rozwiązanie**:
```cmd
del /f /s /q node_modules
del package-lock.json
npm install
```

### Problem: "pip: command not found"
**Rozwiązanie**:
```cmd
python -m ensurepip --upgrade
```

### Problem: Backend nie łączy się z Supabase
**Rozwiązanie**:
1. Sprawdź czy `.env` ma poprawne klucze
2. Sprawdź czy w Supabase utworzone są tabele (uruchom migracje)
3. Zobacz logi: backend zwykle pokazuje szczegółowy błąd

### Problem: Port 8000 lub 5173 jest zajęty
**Rozwiązanie**:
```cmd
# Znajdź proces używający portu
netstat -ano | findstr :8000

# Zabij proces (zamień PID na numer z poprzedniej komendy)
taskkill /PID <numer_PID> /F
```

### Problem: Błędy z venv na Windows
**Rozwiązanie**:
Jeśli masz problem z aktywacją venv, użyj PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
cd backend
.\venv\Scripts\Activate.ps1
```

---

## Testowanie

### Frontend:
```cmd
npm test
```

### Backend:
```cmd
cd backend
venv\Scripts\activate
pytest
```

---

## Build produkcyjny

### Frontend:
```cmd
npm run build
```
Pliki produkcyjne będą w folderze `dist/`

### Backend:
Backend używa FastAPI/Uvicorn - gotowy do produkcji bez dodatkowego buildu

---

## Użyteczne komendy

```cmd
# Sprawdź status Pythona
python --version
pip list

# Sprawdź status Node.js
node --version
npm list --depth=0

# Aktualizacja zależności
npm update
pip install --upgrade -r requirements.txt

# Czyszczenie cache
npm cache clean --force
pip cache purge

# Formatowanie kodu
npm run lint
cd backend && black . && cd ..
```

---

## Wsparcie

W razie problemów:
1. Sprawdź logi w konsoli
2. Sprawdź plik README.md
3. Sprawdź GitHub Issues
4. Sprawdź dokumentację:
   - FastAPI: https://fastapi.tiangolo.com/
   - React: https://react.dev/
   - Supabase: https://supabase.com/docs

---

## Następne kroki

1. ✅ Zainstaluj wymagania
2. ✅ Uruchom setup.bat
3. ✅ Skonfiguruj .env
4. ✅ Uruchom aplikację
5. 📊 Sprawdź dashboard pod http://localhost:5173
6. 🔍 Sprawdź API docs pod http://localhost:8000/docs
7. 🎯 Ciesz się analizami NBA!

---

## Licencja & Disclaimer

⚠️ **UWAGA**: Ten system służy wyłącznie do celów edukacyjnych i analitycznych. Nie stanowi porady finansowej ani zachęty do hazardu. Obstawiaj odpowiedzialnie.
