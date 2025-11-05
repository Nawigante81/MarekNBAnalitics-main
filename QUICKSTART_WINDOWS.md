# 🚀 Quick Start Guide - Windows 11

Szybki przewodnik uruchomienia projektu NBA Analytics na Windows 11.

---

## ⚡ Szybkie uruchomienie (3 kroki)

### 1️⃣ Zainstaluj wymagania

- **Node.js**: <https://nodejs.org/> (wersja LTS)
- **Python 3.11+**: <https://www.python.org/downloads/> (**zaznacz "Add to PATH"!**)

### 2️⃣ Uruchom instalację

Kliknij dwukrotnie na:

```cmd
setup.bat
```

lub w terminalu:

```cmd
setup.bat
```

### 3️⃣ Skonfiguruj klucze API

1. Edytuj plik `.env` (zostanie utworzony automatycznie)
2. Uzupełnij klucze:
   - Supabase: <https://supabase.com/> (załóż darmowe konto)
   - The Odds API: <https://the-odds-api.com/> (darmowy klucz)

---

## 🎮 Uruchomienie aplikacji

### Metoda 1: Docker (najłatwiejsza) 🐳 ⭐
```
docker-start.bat
```
**Wymagania:** Docker Desktop for Windows

**Zalety:**
- ✅ Nie musisz instalować Node.js ani Python
- ✅ Kompletna izolacja (nie zamula systemu)
- ✅ Identyczne środowisko jak w produkcji
- ✅ Backend (FastAPI) na http://localhost:8000
- ✅ Frontend (React) na http://localhost

### Metoda 2: Skrypt natywny
```
start.bat
```
**Wymagania:** Node.js + Python zainstalowane

**Zalety:**
- ✅ Szybsze dla development
- ✅ Łatwiejsze debugowanie
- ✅ Backend na http://localhost:8000  
- ✅ Frontend na http://localhost:5173

### Metoda 3: Ręczne uruchomienie

**Terminal 1 - Backend:**
```cmd
cd backend
venv\Scripts\activate
python main.py
```

**Terminal 2 - Frontend:**
```cmd
npm run dev
```

> **💡 Tip:** Jeśli potrzebujesz ręcznie zainstalować zależności Python:
> ```cmd
> cd backend
> venv\Scripts\activate
> pip install -r requirements.txt
> ```

---

## 🛑 Zatrzymanie aplikacji

Kliknij dwukrotnie na:
```
stop.bat
```

Lub zamknij okna terminali (Ctrl+C w każdym oknie).

---

## 🌐 Dostęp do aplikacji

Po uruchomieniu:

**Docker (docker-start.bat):**
- 🎨 **Dashboard**: http://localhost
- 🔌 **API**: http://localhost:8000
- 📚 **API Docs**: http://localhost:8000/docs

**Native (start.bat):**
- 🎨 **Dashboard**: http://localhost:5173
- 🔌 **API**: http://localhost:8000
- 📚 **API Docs**: http://localhost:8000/docs

---

## 📁 Struktura plików

```
MarekNBAnalitics/
│
├── 📜 setup.bat          ← Instalacja (uruchom raz)
├── 🚀 start.bat          ← Start aplikacji
├── 🛑 stop.bat           ← Stop aplikacji
├── ⚙️  .env               ← Konfiguracja (uzupełnij klucze!)
│
├── 🐍 backend/           ← Kod Python (FastAPI)
│   ├── main.py
│   ├── scrapers.py
│   ├── reports.py
│   └── venv/            ← Środowisko Python (auto)
│
├── ⚛️  src/              ← Kod React (Frontend)
│   ├── components/
│   └── App.tsx
│
└── 📦 node_modules/      ← Zależności JS (auto)
```

---

## 🔑 Wymagane klucze API

### Supabase (darmowe)
1. Idź na: https://supabase.com/
2. Zarejestruj się (darmowe konto)
3. Utwórz nowy projekt
4. Settings → API → skopiuj:
   - `Project URL` → `VITE_SUPABASE_URL`
   - `anon public` → `VITE_SUPABASE_ANON_KEY`

### The Odds API (darmowe 500 requestów/miesiąc)
1. Idź na: https://the-odds-api.com/
2. Zarejestruj się
3. Skopiuj API key → `VITE_ODDS_API_KEY`

### Przykład .env:
```env
VITE_API_BASE_URL=http://localhost:8000
VITE_SUPABASE_URL=https://xyz.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_ODDS_API_KEY=abc123xyz789...
VITE_APP_TIMEZONE=America/Chicago
VITE_REFRESH_INTERVAL=30000
```

---

## ❓ Rozwiązywanie problemów

### ❌ "python nie jest rozpoznawany"
**Rozwiązanie:** Zainstaluj Python ponownie i **ZAZNACZ "Add Python to PATH"**

### ❌ "node nie jest rozpoznawany"
**Rozwiązanie:** Zainstaluj Node.js i zrestartuj komputer

### ❌ Port 8000 lub 5173 zajęty
**Rozwiązanie:**
```cmd
netstat -ano | findstr :8000
taskkill /PID <numer> /F
```

### ❌ Błąd podczas npm install
**Rozwiązanie:**
```cmd
npm cache clean --force
del package-lock.json
npm install
```

### ❌ Backend nie łączy się z bazą
**Rozwiązanie:**
1. Sprawdź czy `.env` ma poprawne klucze
2. Sprawdź czy projekt Supabase jest aktywny
3. Zobacz logi w terminalu backendu

### ❌ ModuleNotFoundError: No module named 'fastapi'
**Rozwiązanie:**
```powershell
# Pakiety nie są zainstalowane w venv!
cd backend
.\venv\Scripts\Activate.ps1  # PowerShell
# LUB
venv\Scripts\activate.bat     # Command Prompt

# Zainstaluj w venv
pip install -r requirements.txt

# Sprawdź
pip list | findstr fastapi
```

📖 **Szczegóły:** [TROUBLESHOOTING_VENV.md](TROUBLESHOOTING_VENV.md)

---

## 📚 Pełna dokumentacja

Szczegółowa instrukcja: **[WINDOWS_SETUP.md](WINDOWS_SETUP.md)**

Dokumentacja projektu: **[README.md](README.md)**

---

## 🆘 Pomoc

Nie działa? Sprawdź:
1. ✅ Czy zainstalowałeś Node.js i Python?
2. ✅ Czy uruchomiłeś `setup.bat`?
3. ✅ Czy uzupełniłeś klucze w `.env`?
4. ✅ Czy Supabase projekt jest aktywny?
5. ✅ Czy masz dostęp do internetu?

Jeśli nadal problem - zobacz logi w terminalach.

---

## 🎯 Co dalej?

Po uruchomieniu:
1. 🌐 Otwórz http://localhost:5173
2. 📊 Zobacz dashboard z analizami NBA
3. 🏀 Sprawdź raporty dla Chicago Bulls
4. 💰 Przejrzyj rekomendacje zakładów
5. 📈 Analizuj trendy i statystyki

---

**Powodzenia! 🏀🚀**

*Projekt NBA Analytics - Automatyczna analiza danych NBA i system wsparcia zakładów sportowych*
