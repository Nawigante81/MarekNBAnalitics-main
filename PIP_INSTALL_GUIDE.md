# 🐍 Python - Prawidłowe komendy instalacji

## ✅ Prawidłowe komendy pip

### W środowisku wirtualnym (venv) - ZALECANE

```cmd
# Krok 1: Utwórz środowisko wirtualne
python -m venv venv

# Krok 2: Aktywuj środowisko (Windows)
venv\Scripts\activate

# Krok 3: Zaktualizuj pip (opcjonalnie, ale zalecane)
python -m pip install --upgrade pip

# Krok 4: Zainstaluj zależności
pip install -r requirements.txt
```

### PowerShell (jeśli cmd nie działa)

```powershell
# Pozwól na uruchamianie skryptów (tylko raz)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Aktywuj venv
.\venv\Scripts\Activate.ps1

# Zainstaluj zależności
pip install -r requirements.txt
```

### Bez środowiska wirtualnego (NIE ZALECANE)

```cmd
# Instalacja globalna (może spowodować konflikty)
pip install -r requirements.txt
```

---

## 📋 Struktura requirements.txt

Nasz projekt używa następujących zależności:

```txt
# Web Framework
fastapi==0.104.1          # Backend API framework
uvicorn[standard]==0.24.0 # ASGI server

# Database
supabase==2.4.0          # Klient Supabase
asyncpg==0.29.0          # PostgreSQL async driver

# Scheduling
APScheduler==3.10.4      # Harmonogram raportów

# Web Scraping
aiohttp==3.9.1           # Async HTTP
httpx==0.25.2            # HTTP client
beautifulsoup4==4.12.2   # HTML parser
lxml==4.9.3              # XML/HTML processor

# Data Analysis
pandas==2.1.4            # Data frames
numpy==1.24.3            # Numeryczne obliczenia

# NBA API
nba-api==1.3.1           # Oficjalne API NBA

# Utilities
pytz==2023.3             # Strefy czasowe
python-dotenv==1.0.0     # Zmienne środowiskowe
loguru==0.7.2            # Logging

# Testing
pytest==7.4.3            # Framework testowy
pytest-asyncio==0.21.1   # Testy async
```

---

## 🔧 Najczęstsze problemy i rozwiązania

### Problem 1: "pip nie jest rozpoznawany"

**Rozwiązanie:**
```cmd
# Użyj pełnej ścieżki do pip
python -m pip install -r requirements.txt
```

### Problem 2: "Permission denied" / "Access denied"

**Rozwiązanie:**
```cmd
# Dodaj --user (instalacja dla użytkownika)
pip install --user -r requirements.txt

# LUB uruchom cmd jako Administrator
```

### Problem 3: Konflikt wersji pakietów

**Rozwiązanie:**
```cmd
# Usuń stare pakiety
pip uninstall -y -r requirements.txt

# Zainstaluj od nowa
pip install -r requirements.txt
```

### Problem 4: Błąd podczas instalacji lxml lub innych pakietów C

**Rozwiązanie:**
```cmd
# Zainstaluj Microsoft C++ Build Tools
# Pobierz z: https://visualstudio.microsoft.com/visual-cpp-build-tools/

# LUB użyj pre-compiled wheels
pip install --only-binary :all: -r requirements.txt
```

### Problem 5: Timeout podczas instalacji

**Rozwiązanie:**
```cmd
# Zwiększ timeout
pip install --timeout 1000 -r requirements.txt

# LUB użyj innego mirror
pip install -i https://pypi.org/simple -r requirements.txt
```

### Problem 6: SSL Certificate Error

**Rozwiązanie:**
```cmd
# Tymczasowo wyłącz weryfikację SSL (nie zalecane!)
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt
```

---

## 🚀 Automatyczna instalacja w projekcie

Nasz projekt zawiera skrypt `setup.bat`, który automatycznie:

1. ✅ Sprawdza czy Python jest zainstalowany
2. ✅ Tworzy środowisko wirtualne (`venv`)
3. ✅ Aktywuje środowisko
4. ✅ Aktualizuje pip do najnowszej wersji
5. ✅ Instaluje wszystkie zależności z `requirements.txt`

**Użycie:**
```cmd
setup.bat
```

---

## 📦 Dodawanie nowych pakietów

### Metoda 1: Ręczne dodanie do requirements.txt

```txt
# Dodaj na końcu pliku
nowy-pakiet==1.2.3
```

Następnie:
```cmd
pip install -r requirements.txt
```

### Metoda 2: Instalacja i automatyczne dodanie

```cmd
# Zainstaluj pakiet
pip install nowy-pakiet

# Wygeneruj requirements.txt
pip freeze > requirements.txt
```

**⚠️ UWAGA:** `pip freeze` może dodać wszystkie zależności, nawet te niepotrzebne. Lepiej edytować ręcznie.

---

## 🔍 Sprawdzanie zainstalowanych pakietów

```cmd
# Lista wszystkich pakietów
pip list

# Szczegóły konkretnego pakietu
pip show fastapi

# Sprawdź czy pakiet jest zainstalowany
pip show pakiet-name || echo Pakiet nie jest zainstalowany

# Sprawdź przestarzałe pakiety
pip list --outdated
```

---

## 🔄 Aktualizacja pakietów

```cmd
# Aktualizacja konkretnego pakietu
pip install --upgrade nazwa-pakietu

# Aktualizacja wszystkich pakietów (OSTROŻNIE!)
pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U

# Bezpieczniejsza metoda - aktualizacja po kolei
pip install --upgrade fastapi
pip install --upgrade uvicorn
# itd...
```

---

## 🧹 Czyszczenie i odinstalowanie

```cmd
# Odinstaluj pojedynczy pakiet
pip uninstall nazwa-pakietu

# Odinstaluj wszystkie pakiety z requirements.txt
pip uninstall -y -r requirements.txt

# Wyczyść cache pip
pip cache purge

# Usuń środowisko wirtualne (Windows)
rmdir /s /q venv

# Utwórz nowe środowisko od zera
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

---

## 📊 Weryfikacja instalacji

### Test 1: Sprawdź czy wszystkie pakiety są zainstalowane

```cmd
pip check
```

### Test 2: Sprawdź importy Python

```cmd
python -c "import fastapi; import pandas; import supabase; print('✅ Wszystkie pakiety działają!')"
```

### Test 3: Sprawdź wersje

```cmd
python -c "import fastapi; print(f'FastAPI: {fastapi.__version__}')"
python -c "import pandas; print(f'Pandas: {pandas.__version__}')"
```

### Test 4: Uruchom backend (ostateczny test)

```cmd
cd backend
python main.py
```

Jeśli widzisz `Uvicorn running on http://0.0.0.0:8000` - wszystko działa! ✅

---

## 🎯 Best Practices

### ✅ DO (Zalecane):
- ✅ Używaj środowiska wirtualnego (`venv`)
- ✅ Aktywuj venv przed każdą pracą
- ✅ Trzymaj `requirements.txt` w kontroli wersji
- ✅ Używaj konkretnych wersji pakietów (`==`)
- ✅ Regularnie aktualizuj `pip`: `python -m pip install --upgrade pip`

### ❌ DON'T (Niezalecane):
- ❌ Nie instaluj pakietów globalnie (bez venv)
- ❌ Nie używaj `pip freeze > requirements.txt` bez przeglądu
- ❌ Nie mieszaj środowisk (conda + venv)
- ❌ Nie commituj folderu `venv/` do Git
- ❌ Nie używaj `sudo pip install` (Linux/Mac)

---

## 📝 Podsumowanie komend

### Podstawowy workflow:

```cmd
# 1. Sklonuj/pobierz projekt
git clone https://github.com/Nawigante81/MarekNBAnalitics
cd MarekNBAnalitics

# 2. Utwórz i aktywuj venv
python -m venv venv
venv\Scripts\activate

# 3. Zaktualizuj pip
python -m pip install --upgrade pip

# 4. Zainstaluj zależności
cd backend
pip install -r requirements.txt

# 5. Sprawdź instalację
pip check
python -c "import fastapi; print('OK')"

# 6. Uruchom aplikację
python main.py
```

---

## 🆘 Pomoc

Jeśli nadal masz problemy:

1. **Sprawdź wersję Python**: `python --version` (powinna być 3.11+)
2. **Sprawdź wersję pip**: `pip --version`
3. **Sprawdź czy venv jest aktywny**: `where python` (powinno pokazać ścieżkę z `venv`)
4. **Zobacz szczegółowe logi**: `pip install -v -r requirements.txt`
5. **Sprawdź dokumentację**: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)

---

**✅ Prawidłowa komenda to zawsze: `pip install -r requirements.txt`**

*Instrukcja przygotowana dla projektu MarekNBAnalitics - NBA Analysis & Betting System*
