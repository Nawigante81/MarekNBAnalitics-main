# 🔴 ModuleNotFoundError: No module named 'fastapi'

## Problem

```
Traceback (most recent call last):
  File "C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend\main.py", line 9, in <module>
    from fastapi import FastAPI, HTTPException
ModuleNotFoundError: No module named 'fastapi'

(venv) C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend>
```

**Przyczyna:** Pakiety Python NIE zostały zainstalowane wewnątrz środowiska wirtualnego (venv).

---

## ✅ Rozwiązanie krok po kroku

### Krok 1: Upewnij się, że venv jest aktywne

Powinieneś widzieć `(venv)` na początku linii:

```powershell
(venv) C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend>
```

✅ **Widzę** `(venv)` - dobrze!

### Krok 2: Sprawdź który Python jest używany

```powershell
where python
```

**Powinno pokazać:**
```
C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend\venv\Scripts\python.exe
```

Jeśli pokazuje inną ścieżkę (np. `C:\Python311\python.exe`), to venv NIE jest aktywny!

### Krok 3: Zainstaluj pakiety W ŚRODOWISKU VENV

```powershell
# Upewnij się, że jesteś w folderze backend
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend

# Aktywuj venv (jeśli nieaktywny)
.\venv\Scripts\Activate.ps1

# Zaktualizuj pip W VENV
python -m pip install --upgrade pip

# Zainstaluj zależności W VENV
pip install -r requirements.txt
```

### Krok 4: Sprawdź instalację

```powershell
# Sprawdź czy fastapi jest zainstalowany W VENV
pip list | findstr fastapi

# Lub sprawdź import
python -c "import fastapi; print('✅ FastAPI działa!')"
```

### Krok 5: Uruchom aplikację

```powershell
python main.py
```

---

## 🚨 Najczęstsze przyczyny problemu

### Problem 1: Zainstalowałeś pakiety BEZ aktywnego venv

❌ **Źle:**
```powershell
# Bez aktywacji venv
pip install -r requirements.txt  # Instaluje GLOBALNIE!
```

✅ **Dobrze:**
```powershell
# Z aktywnym venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt  # Instaluje W VENV
```

### Problem 2: Używasz Command Prompt zamiast PowerShell

W Command Prompt (cmd) aktywacja to:
```cmd
venv\Scripts\activate.bat
```

W PowerShell aktywacja to:
```powershell
.\venv\Scripts\Activate.ps1
```

### Problem 3: PowerShell blokuje uruchamianie skryptów

**Błąd:**
```
.\venv\Scripts\Activate.ps1 : File cannot be loaded because running scripts is disabled
```

**Rozwiązanie:**
```powershell
# Uruchom JEDEN RAZ jako Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem 4: Venv nie został prawidłowo utworzony

**Rozwiązanie - utwórz od nowa:**
```powershell
# Usuń stary venv
Remove-Item -Recurse -Force venv

# Utwórz nowy
python -m venv venv

# Aktywuj
.\venv\Scripts\Activate.ps1

# Zainstaluj
pip install -r requirements.txt
```

---

## 🔧 Kompletne rozwiązanie (kopiuj-wklej)

```powershell
# 1. Przejdź do folderu backend
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend

# 2. Usuń stary venv (jeśli jest uszkodzony)
Remove-Item -Recurse -Force venv -ErrorAction SilentlyContinue

# 3. Utwórz nowy venv
python -m venv venv

# 4. Aktywuj venv (PowerShell)
.\venv\Scripts\Activate.ps1

# 5. Sprawdź czy venv jest aktywny (powinno pokazać ścieżkę z \venv\)
where python

# 6. Zaktualizuj pip
python -m pip install --upgrade pip

# 7. Zainstaluj zależności
pip install -r requirements.txt

# 8. Sprawdź instalację
pip list

# 9. Test importu
python -c "import fastapi; print('✅ OK!')"

# 10. Uruchom aplikację
python main.py
```

**Jeśli używasz Command Prompt (cmd):**
```cmd
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend
rmdir /s /q venv
python -m venv venv
venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt
python main.py
```

---

## 🎯 Weryfikacja, że wszystko działa

### Test 1: Sprawdź venv
```powershell
# Powinno pokazać (venv) przed ścieżką
# (venv) C:\Users\pytla\Desktop\...
```

### Test 2: Sprawdź Python path
```powershell
where python
# Powinno pokazać: ...\backend\venv\Scripts\python.exe
```

### Test 3: Sprawdź zainstalowane pakiety
```powershell
pip list
# Powinno pokazać: fastapi, uvicorn, supabase, itd.
```

### Test 4: Sprawdź importy
```powershell
python -c "import fastapi, uvicorn, supabase; print('✅ Wszystko zainstalowane!')"
```

### Test 5: Uruchom backend
```powershell
python main.py
# Powinno pokazać: "Uvicorn running on http://0.0.0.0:8000"
```

---

## 📋 Checklist debugowania

- [ ] Jestem w folderze `backend`?
- [ ] Widzę `(venv)` przed ścieżką w terminalu?
- [ ] `where python` pokazuje ścieżkę z `\venv\Scripts\`?
- [ ] `pip list` pokazuje zainstalowane pakiety?
- [ ] Plik `requirements.txt` istnieje w `backend/`?
- [ ] Python 3.11+ jest zainstalowany? (`python --version`)
- [ ] Mam dostęp do internetu (do pobrania pakietów)?

---

## 🆘 Nadal nie działa?

### Opcja 1: Użyj setup.bat
```cmd
# W głównym folderze projektu (nie backend!)
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main
setup.bat
```

### Opcja 2: Zainstaluj globalnie (NIE ZALECANE, ale działa)
```powershell
# Bez venv - instalacja globalna
cd C:\Users\pytla\Desktop\MarekNBAnalitics-main\backend
pip install -r requirements.txt
python main.py
```

### Opcja 3: Zobacz szczegółowe logi
```powershell
pip install -v -r requirements.txt
```

### Opcja 4: Sprawdź czy Python może tworzyć venv
```powershell
python -m venv --help
# Jeśli błąd: zainstaluj ponownie Python z "pip" zaznaczonym
```

---

## 💡 Najlepsza praktyka na przyszłość

**Zawsze przed pracą:**
```powershell
cd backend
.\venv\Scripts\Activate.ps1  # Aktywuj venv
# Teraz możesz pracować
```

**Zawsze instaluj pakiety Z AKTYWNYM VENV:**
```powershell
(venv) > pip install nazwa-pakietu
```

---

## ✅ Podsumowanie

1. **Aktywuj venv**: `.\venv\Scripts\Activate.ps1` (PowerShell) lub `venv\Scripts\activate.bat` (cmd)
2. **Zainstaluj pakiety W venv**: `pip install -r requirements.txt`
3. **Sprawdź**: `pip list | findstr fastapi`
4. **Uruchom**: `python main.py`

**Pamiętaj:** Pakiety muszą być zainstalowane WEWNĄTRZ środowiska wirtualnego (venv), nie globalnie!

---

**Problem powinien być rozwiązany! 🎉**

Jeśli nadal nie działa, wyślij screenshot z:
1. `where python`
2. `pip list`
3. Pełny błąd
