# 🗄️ Konfiguracja bazy danych Supabase

## 📋 Struktura tabel

Projekt wymaga 3 tabel w Supabase:

### 1. Tabela `teams` - Zespoły NBA

```sql
CREATE TABLE IF NOT EXISTS public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  abbreviation text UNIQUE NOT NULL,
  full_name text NOT NULL,
  name text NOT NULL,
  city text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_teams_abbreviation ON public.teams(abbreviation);
```

**Kolumny:**
- `id` - UUID, klucz główny
- `abbreviation` - Skrót drużyny (np. "CHI", "LAL", "BOS")
- `full_name` - Pełna nazwa (np. "Chicago Bulls")
- `name` - Nazwa drużyny (np. "Bulls")
- `city` - Miasto (np. "Chicago")
- `created_at` - Data utworzenia rekordu

**Przykładowe dane:**
```sql
INSERT INTO public.teams (abbreviation, full_name, name, city) VALUES
  ('CHI', 'Chicago Bulls', 'Bulls', 'Chicago'),
  ('LAL', 'Los Angeles Lakers', 'Lakers', 'Los Angeles'),
  ('BOS', 'Boston Celtics', 'Celtics', 'Boston'),
  ('GSW', 'Golden State Warriors', 'Warriors', 'Golden State'),
  ('MIA', 'Miami Heat', 'Heat', 'Miami');
```

---

### 2. Tabela `games` - Mecze NBA

```sql
CREATE TABLE IF NOT EXISTS public.games (
  id text PRIMARY KEY,
  sport_key text,
  sport_title text,
  commence_time timestamptz NOT NULL,
  home_team text NOT NULL,
  away_team text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_games_commence_time ON public.games(commence_time);
```

**Kolumny:**
- `id` - ID meczu z API (np. "abc123xyz")
- `sport_key` - Klucz sportu (np. "basketball_nba")
- `sport_title` - Tytuł sportu (np. "NBA")
- `commence_time` - Data i godzina rozpoczęcia meczu
- `home_team` - Drużyna gospodarzy
- `away_team` - Drużyna gości
- `created_at` - Data utworzenia rekordu
- `updated_at` - Data ostatniej aktualizacji

---

### 3. Tabela `odds` - Kursy bukmacherskie

```sql
CREATE TABLE IF NOT EXISTS public.odds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id text NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  bookmaker_key text NOT NULL,
  bookmaker_title text,
  last_update timestamptz,
  market_type text NOT NULL,
  team text,
  outcome_name text,
  point numeric,
  price numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_odds_game_id ON public.odds(game_id);
CREATE INDEX IF NOT EXISTS idx_odds_bookmaker_key ON public.odds(bookmaker_key);
CREATE INDEX IF NOT EXISTS idx_odds_market_type ON public.odds(market_type);
```

**Kolumny:**
- `id` - UUID, klucz główny
- `game_id` - ID meczu (foreign key do `games.id`)
- `bookmaker_key` - Identyfikator bukmachera (np. "draftkings", "betmgm")
- `bookmaker_title` - Nazwa wyświetlana (np. "DraftKings", "BetMGM")
- `last_update` - Kiedy kursy zostały zaktualizowane
- `market_type` - Typ zakładu: "h2h" (zwycięzca), "spread" (handicap), "totals" (over/under)
- `team` - Nazwa drużyny (dla h2h i spread)
- `outcome_name` - Nazwa wyniku (dla totals: "Over" lub "Under")
- `point` - Linia handicapu lub totals
- `price` - Kurs (odds)
- `created_at` - Data utworzenia
- `updated_at` - Data aktualizacji

---

## 🔐 Polityki RLS (Row Level Security)

### Opcja 1: Brak zabezpieczeń (dla testów/development)

Wyłącz RLS dla wszystkich tabel (NIE zalecane w produkcji):

```sql
ALTER TABLE public.teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.games DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.odds DISABLE ROW LEVEL SECURITY;
```

---

### Opcja 2: Podstawowe polityki (zalecane)

#### Polityki dla tabeli `teams`

```sql
-- Włącz RLS
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Polityka: Wszyscy mogą czytać
CREATE POLICY "Enable read access for all users" ON public.teams
  FOR SELECT USING (true);

-- Polityka: Tylko serwis może zapisywać (używając service_role key)
CREATE POLICY "Enable insert for service role only" ON public.teams
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Enable update for service role only" ON public.teams
  FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "Enable delete for service role only" ON public.teams
  FOR DELETE USING (auth.role() = 'service_role');
```

#### Polityki dla tabeli `games`

```sql
-- Włącz RLS
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- Polityka: Wszyscy mogą czytać
CREATE POLICY "Enable read access for all users" ON public.games
  FOR SELECT USING (true);

-- Polityka: Tylko serwis może zapisywać
CREATE POLICY "Enable insert for service role only" ON public.games
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Enable update for service role only" ON public.games
  FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "Enable delete for service role only" ON public.games
  FOR DELETE USING (auth.role() = 'service_role');
```

#### Polityki dla tabeli `odds`

```sql
-- Włącz RLS
ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;

-- Polityka: Wszyscy mogą czytać
CREATE POLICY "Enable read access for all users" ON public.odds
  FOR SELECT USING (true);

-- Polityka: Tylko serwis może zapisywać
CREATE POLICY "Enable insert for service role only" ON public.odds
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Enable update for service role only" ON public.odds
  FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "Enable delete for service role only" ON public.odds
  FOR DELETE USING (auth.role() = 'service_role');
```

---

### Opcja 3: Pełny dostęp publiczny (najprostsze dla tego projektu)

```sql
-- Włącz RLS
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;

-- Pełny dostęp dla wszystkich operacji
CREATE POLICY "Allow all operations" ON public.teams FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON public.games FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON public.odds FOR ALL USING (true);
```

---

## 🚀 Jak uruchomić w Supabase?

### Metoda 1: Użyj gotowego pliku SQL (NAJŁATWIEJSZA) ⭐

**Opcja A - Prosty setup (zalecane):**
1. Otwórz plik: **`supabase_setup_simple.sql`**
2. Skopiuj całą zawartość (Ctrl+A, Ctrl+C)
3. Zaloguj się do Supabase: https://supabase.com/dashboard
4. Wybierz swój projekt
5. Kliknij **SQL Editor** w lewym menu
6. Kliknij **New Query**
7. Wklej skopiowany kod (Ctrl+V)
8. Kliknij **Run** (lub naciśnij Ctrl+Enter)
9. ✅ Gotowe!

**Opcja B - Pełny setup (z funkcjami i widokami):**
- Użyj pliku: **`supabase_setup_complete.sql`**
- Ten sam proces jak wyżej

### Metoda 2: Ręczne kopiowanie z dokumentacji

1. Zaloguj się do Supabase: https://supabase.com/dashboard
2. Wybierz swój projekt
3. Kliknij **SQL Editor** w lewym menu
4. Kliknij **New Query**
5. Skopiuj i wklej poniższy kod:

```sql
-- ============================================
-- KOMPLETNA KONFIGURACJA BAZY DANYCH NBA
-- ============================================

-- 1. Utwórz tabele
CREATE TABLE IF NOT EXISTS public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  abbreviation text UNIQUE NOT NULL,
  full_name text NOT NULL,
  name text NOT NULL,
  city text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.games (
  id text PRIMARY KEY,
  sport_key text,
  sport_title text,
  commence_time timestamptz NOT NULL,
  home_team text NOT NULL,
  away_team text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.odds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id text NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  bookmaker_key text NOT NULL,
  bookmaker_title text,
  last_update timestamptz,
  market_type text NOT NULL,
  team text,
  outcome_name text,
  point numeric,
  price numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Utwórz indeksy
CREATE INDEX IF NOT EXISTS idx_teams_abbreviation ON public.teams(abbreviation);
CREATE INDEX IF NOT EXISTS idx_games_commence_time ON public.games(commence_time);
CREATE INDEX IF NOT EXISTS idx_odds_game_id ON public.odds(game_id);
CREATE INDEX IF NOT EXISTS idx_odds_bookmaker_key ON public.odds(bookmaker_key);
CREATE INDEX IF NOT EXISTS idx_odds_market_type ON public.odds(market_type);

-- 3. Włącz RLS (Row Level Security)
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;

-- 4. Utwórz polityki (pełny dostęp dla uproszczenia)
CREATE POLICY "Allow all operations" ON public.teams FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON public.games FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON public.odds FOR ALL USING (true);

-- 5. Dodaj przykładowe dane dla zespołów
INSERT INTO public.teams (abbreviation, full_name, name, city) VALUES
  ('CHI', 'Chicago Bulls', 'Bulls', 'Chicago'),
  ('LAL', 'Los Angeles Lakers', 'Lakers', 'Los Angeles'),
  ('BOS', 'Boston Celtics', 'Celtics', 'Boston'),
  ('GSW', 'Golden State Warriors', 'Warriors', 'Golden State'),
  ('MIA', 'Miami Heat', 'Heat', 'Miami'),
  ('MIL', 'Milwaukee Bucks', 'Bucks', 'Milwaukee'),
  ('PHX', 'Phoenix Suns', 'Suns', 'Phoenix'),
  ('DEN', 'Denver Nuggets', 'Nuggets', 'Denver'),
  ('DAL', 'Dallas Mavericks', 'Mavericks', 'Dallas'),
  ('PHI', 'Philadelphia 76ers', '76ers', 'Philadelphia'),
  ('NYK', 'New York Knicks', 'Knicks', 'New York'),
  ('BKN', 'Brooklyn Nets', 'Nets', 'Brooklyn'),
  ('CLE', 'Cleveland Cavaliers', 'Cavaliers', 'Cleveland'),
  ('TOR', 'Toronto Raptors', 'Raptors', 'Toronto'),
  ('ATL', 'Atlanta Hawks', 'Hawks', 'Atlanta'),
  ('ORL', 'Orlando Magic', 'Magic', 'Orlando'),
  ('IND', 'Indiana Pacers', 'Pacers', 'Indiana'),
  ('DET', 'Detroit Pistons', 'Pistons', 'Detroit'),
  ('WAS', 'Washington Wizards', 'Wizards', 'Washington'),
  ('CHA', 'Charlotte Hornets', 'Hornets', 'Charlotte'),
  ('SAC', 'Sacramento Kings', 'Kings', 'Sacramento'),
  ('LAC', 'Los Angeles Clippers', 'Clippers', 'Los Angeles'),
  ('POR', 'Portland Trail Blazers', 'Trail Blazers', 'Portland'),
  ('UTA', 'Utah Jazz', 'Jazz', 'Utah'),
  ('MIN', 'Minnesota Timberwolves', 'Timberwolves', 'Minnesota'),
  ('OKC', 'Oklahoma City Thunder', 'Thunder', 'Oklahoma City'),
  ('MEM', 'Memphis Grizzlies', 'Grizzlies', 'Memphis'),
  ('NOP', 'New Orleans Pelicans', 'Pelicans', 'New Orleans'),
  ('SAS', 'San Antonio Spurs', 'Spurs', 'San Antonio'),
  ('HOU', 'Houston Rockets', 'Rockets', 'Houston')
ON CONFLICT (abbreviation) DO NOTHING;
```

6. Kliknij **Run** lub naciśnij `Ctrl+Enter`
7. ✅ Gotowe!

---

### Metoda 2: Supabase CLI (dla zaawansowanych)

```bash
# Zainstaluj Supabase CLI
npm install -g supabase

# Zaloguj się
supabase login

# Link do projektu
supabase link --project-ref twoj-projekt-ref

# Uruchom migracje
supabase db push
```

---

## 🔍 Weryfikacja instalacji

Po uruchomieniu powyższego SQL, sprawdź w Dashboard:

1. **Table Editor** → Powinieneś widzieć 3 tabele:
   - `teams` (z 30 drużynami NBA)
   - `games` (pusta)
   - `odds` (pusta)

2. **SQL Editor** → Sprawdź dane:
```sql
-- Sprawdź drużyny
SELECT * FROM public.teams ORDER BY city;

-- Sprawdź strukturę
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teams';
```

---

## 📊 Diagram relacji

```
┌─────────────┐
│   teams     │
│─────────────│
│ id          │
│ abbreviation│◄────┐
│ full_name   │     │
│ name        │     │
│ city        │     │
└─────────────┘     │
                    │ (used for lookups)
                    │
┌─────────────┐     │
│   games     │     │
│─────────────│     │
│ id          │◄────┼─────┐
│ sport_key   │     │     │
│ commence_time│    │     │
│ home_team   ├─────┘     │
│ away_team   ├───────────┘
└─────────────┘           
       │                  
       │ 1:N              
       │                  
┌─────────────┐           
│    odds     │           
│─────────────│           
│ id          │           
│ game_id     │───────────┘
│ bookmaker   │
│ market_type │
│ price       │
└─────────────┘
```

---

## 🔑 Klucze API potrzebne w .env

Po utworzeniu tabel, skopiuj klucze z Supabase Dashboard:

```env
# Project Settings → API
VITE_SUPABASE_URL=https://twoj-projekt.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ✅ Podsumowanie

| Tabela | Wiersze | Polityki | Status |
|--------|---------|----------|--------|
| `teams` | 30 drużyn NBA | RLS włączone, pełny dostęp | ✅ Gotowe |
| `games` | Wypełniane przez API | RLS włączone, pełny dostęp | ✅ Gotowe |
| `odds` | Wypełniane przez API | RLS włączone, pełny dostęp | ✅ Gotowe |

**Następne kroki:**
1. ✅ Uruchom SQL w Supabase
2. ✅ Skopiuj klucze API do `.env`
3. ✅ Uruchom backend: `python main.py`
4. ✅ Backend automatycznie wypełni tabele `games` i `odds`

---

**Baza danych gotowa! 🎉**
