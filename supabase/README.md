# 🗄️ Pliki SQL dla Supabase

## Szybkie uruchomienie bazy danych

### 📄 Dostępne pliki:

| Plik | Opis | Kiedy użyć |
|------|------|------------|
| **supabase_setup_simple.sql** | Podstawowy setup (tabele + dane) | ✅ Zalecane dla większości użytkowników |
| **supabase_setup_complete.sql** | Pełny setup (+ funkcje, widoki, triggery) | Dla zaawansowanych użytkowników |

---

## 🚀 Jak użyć?

### Krok 1: Wybierz plik
Dla prostego uruchomienia użyj: **supabase_setup_simple.sql**

### Krok 2: Skopiuj zawartość
- Otwórz plik w edytorze tekstu
- Zaznacz wszystko (Ctrl+A)
- Skopiuj (Ctrl+C)

### Krok 3: Uruchom w Supabase
1. Zaloguj się: https://supabase.com/dashboard
2. Wybierz projekt
3. Kliknij **SQL Editor** (lewe menu)
4. Kliknij **New Query**
5. Wklej skopiowany kod (Ctrl+V)
6. Kliknij **Run** lub Ctrl+Enter
7. ✅ Gotowe!

---

## 📊 Co zostanie utworzone?

### Tabele:
- ✅ **teams** - 30 drużyn NBA
- ✅ **games** - Mecze (wypełniane przez backend)
- ✅ **odds** - Kursy bukmacherskie (wypełniane przez backend)

### Bezpieczeństwo:
- ✅ Row Level Security (RLS) włączone
- ✅ Polityki dostępu ustawione
- ✅ Indeksy dla szybkich zapytań

---

## 🔍 Weryfikacja

Po uruchomieniu sprawdź w Supabase Dashboard:

**Table Editor** → Powinieneś zobaczyć:
- `teams` (30 wierszy z drużynami NBA)
- `games` (pusta, na razie)
- `odds` (pusta, na razie)

---

## 📚 Szczegółowa dokumentacja

Zobacz: **SUPABASE_SETUP.md** - kompletna dokumentacja struktury bazy danych.

---

## 🆘 Problemy?

### Błąd: "relation already exists"
**Rozwiązanie:** Tabele już istnieją. Skrypt automatycznie je usuwa i tworzy od nowa.

### Błąd: "permission denied"
**Rozwiązanie:** Upewnij się, że masz uprawnienia do tworzenia tabel w projekcie Supabase.

### Nie widzę drużyn w tabeli teams
**Rozwiązanie:** Sprawdź czy cały skrypt się wykonał (przewiń w dół wyników w SQL Editor).

---

## ✅ Następne kroki

Po konfiguracji bazy:

1. Skopiuj klucze API z Supabase
2. Wklej do pliku `.env`
3. Uruchom backend: `python main.py`
4. Backend wypełni tabele `games` i `odds`

---

**Gotowe do użycia! 🎉**
