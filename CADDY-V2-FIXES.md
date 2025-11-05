# Caddy v2 - Poprawki składni

## Problem
Użyłem niepoprawnej składni z Caddy v1 w konfiguracji v2. Główne błędy:

1. **Zbędny nagłówek**: `header_up X-Forwarded-Proto {scheme}` - automatyczny w v2
2. **Niepoprawne logowanie**: `rotate {}` nie istnieje w v2
3. **Niepoprawne jednostki**: `mb` zamiast `MiB`

## Rozwiązanie

### 1. Usuń zbędny nagłówek X-Forwarded-Proto

**❌ Niepoprawnie (v1 style):**
```caddyfile
reverse_proxy localhost:8000 {
    header_up X-Forwarded-Proto {scheme}  # USUŃ TO
}
```

**✅ Prawidłowo (v2 style):**
```caddyfile
reverse_proxy localhost:8000 {
    # X-Forwarded-Proto jest automatycznie ustawiany
}
```

### 2. Popraw składnię logowania

**❌ Niepoprawnie (v1 style):**
```caddyfile
log {
    output file /var/log/caddy/access.log
    rotate {
        size 10MB        # Błąd: brak rotate w v2
        keep 5
        age 720h
    }
}
```

**✅ Prawidłowo (v2 style):**
```caddyfile
log {
    output file /var/log/caddy/access.log {
        roll_size 10MiB      # MiB zamiast MB
        roll_keep 5
        roll_keep_for 720h
    }
    format console
}
```

### 3. Globalna konfiguracja logowania (opcjonalna)

```caddyfile
{
    log {
        output file /var/log/caddy/caddy.log {
            roll_size 10MiB
            roll_keep 5
            roll_keep_for 720h
        }
        format console
    }
}
```

## Komendy naprawy na Raspberry Pi

### 1. Utwórz katalog logów z uprawnieniami
```bash
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy
sudo chmod 755 /var/log/caddy
```

### 2. Skopiuj poprawny Caddyfile
```bash
# Backup obecnej konfiguracji
sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)"

# Zainstaluj poprawną konfigurację (użyj skryptu fix-caddyfile-v2.sh)
chmod +x fix-caddyfile-v2.sh
./fix-caddyfile-v2.sh
```

### 3. Walidacja i formatowanie
```bash
# Formatuj plik konfiguracyjny
sudo caddy fmt --overwrite /etc/caddy/Caddyfile

# Sprawdź poprawność składni
sudo caddy validate --config /etc/caddy/Caddyfile

# Przeładuj usługę
sudo systemctl reload caddy
```

### 4. Sprawdź status
```bash
# Status usługi
sudo systemctl status caddy

# Logi w czasie rzeczywistym
sudo journalctl -u caddy -f

# Sprawdź czy wszystko działa
curl -I http://192.168.100.196/health
```

## Kluczowe różnice v1 vs v2

| Aspekt | Caddy v1 | Caddy v2 |
|--------|----------|----------|
| **Rotacja logów** | `rotate { size 10MB }` | `output file { roll_size 10MiB }` |
| **Jednostki** | `MB`, `GB` | `MiB`, `GiB` |  
| **X-Forwarded-Proto** | Trzeba ustawiać ręcznie | Automatyczne |
| **Format logów** | Domyślnie JSON | Trzeba określić `format console` |
| **Globalny blok** | Nie istniał | `{ ... }` na początku pliku |

## Najczęstsze błędy

1. **`ambiguous site definition`** - duplikaty w definicji hostów
2. **`unknown directive: rotate`** - użycie v1 składni
3. **`parsing caddyfile`** - błędna składnia bloków

## Zweryfikowane pliki

✅ **Naprawione pliki:**
- `Caddyfile` - główny plik konfiguracyjny
- `Caddyfile.pi4` - wersja dla Pi4  
- `Caddyfile.v2-corrected` - poprawna wersja referencyjna
- `deploy-pi4-arm64.sh` - skrypt deploymentu
- `setup-pi4-minimal.sh` - minimalny setup
- `fix-caddyfile-v2.sh` - skrypt automatycznej naprawy

## Test działania

Po naprawie sprawdź czy wszystko działa:

```bash
# 1. Zweryfikuj konfigurację
sudo caddy validate --config /etc/caddy/Caddyfile

# 2. Sprawdź status usług
sudo systemctl status caddy nba-backend nba-frontend

# 3. Testuj endpointy
curl http://192.168.100.196/health      # Health check
curl http://192.168.100.196/api/health  # Backend API
curl http://192.168.100.196/             # Frontend

# 4. Sprawdź logi
tail -f /var/log/caddy/access.log
tail -f /var/log/caddy/caddy.log
```

Jeśli wszystko działa prawidłowo, aplikacja NBA Analytics powinna być dostępna pod adresem `http://192.168.100.196`.