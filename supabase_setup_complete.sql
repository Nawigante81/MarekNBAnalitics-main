-- ============================================
-- KOMPLETNA KONFIGURACJA BAZY DANYCH NBA
-- Projekt: MarekNBAnalitics
-- Wersja: 1.0
-- Data: 2025-11-03
-- ============================================

-- KROK 1: Usuń istniejące tabele (jeśli istnieją)
-- ============================================
DROP TABLE IF EXISTS public.odds CASCADE;
DROP TABLE IF EXISTS public.games CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;

-- KROK 2: Utwórz tabele
-- ============================================

-- Tabela: teams (Zespoły NBA)
CREATE TABLE public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  abbreviation text UNIQUE NOT NULL,
  full_name text NOT NULL,
  name text NOT NULL,
  city text,
  created_at timestamptz DEFAULT now()
);

-- Tabela: games (Mecze NBA)
CREATE TABLE public.games (
  id text PRIMARY KEY,
  sport_key text,
  sport_title text,
  commence_time timestamptz NOT NULL,
  home_team text NOT NULL,
  away_team text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela: odds (Kursy bukmacherskie)
CREATE TABLE public.odds (
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

-- KROK 3: Utwórz indeksy dla optymalizacji zapytań
-- ============================================

-- Indeksy dla tabeli teams
CREATE INDEX idx_teams_abbreviation ON public.teams(abbreviation);
CREATE INDEX idx_teams_city ON public.teams(city);

-- Indeksy dla tabeli games
CREATE INDEX idx_games_commence_time ON public.games(commence_time);
CREATE INDEX idx_games_home_team ON public.games(home_team);
CREATE INDEX idx_games_away_team ON public.games(away_team);

-- Indeksy dla tabeli odds
CREATE INDEX idx_odds_game_id ON public.odds(game_id);
CREATE INDEX idx_odds_bookmaker_key ON public.odds(bookmaker_key);
CREATE INDEX idx_odds_market_type ON public.odds(market_type);
CREATE INDEX idx_odds_last_update ON public.odds(last_update);

-- KROK 4: Włącz Row Level Security (RLS)
-- ============================================

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;

-- KROK 5: Utwórz polityki dostępu
-- ============================================

-- Polityki dla tabeli teams
CREATE POLICY "teams_select_policy" ON public.teams
  FOR SELECT USING (true);

CREATE POLICY "teams_insert_policy" ON public.teams
  FOR INSERT WITH CHECK (true);

CREATE POLICY "teams_update_policy" ON public.teams
  FOR UPDATE USING (true);

CREATE POLICY "teams_delete_policy" ON public.teams
  FOR DELETE USING (true);

-- Polityki dla tabeli games
CREATE POLICY "games_select_policy" ON public.games
  FOR SELECT USING (true);

CREATE POLICY "games_insert_policy" ON public.games
  FOR INSERT WITH CHECK (true);

CREATE POLICY "games_update_policy" ON public.games
  FOR UPDATE USING (true);

CREATE POLICY "games_delete_policy" ON public.games
  FOR DELETE USING (true);

-- Polityki dla tabeli odds
CREATE POLICY "odds_select_policy" ON public.odds
  FOR SELECT USING (true);

CREATE POLICY "odds_insert_policy" ON public.odds
  FOR INSERT WITH CHECK (true);

CREATE POLICY "odds_update_policy" ON public.odds
  FOR UPDATE USING (true);

CREATE POLICY "odds_delete_policy" ON public.odds
  FOR DELETE USING (true);

-- KROK 6: Dodaj dane inicjalne - Wszystkie 30 drużyn NBA
-- ============================================

INSERT INTO public.teams (abbreviation, full_name, name, city) VALUES
  -- Eastern Conference - Atlantic Division
  ('BOS', 'Boston Celtics', 'Celtics', 'Boston'),
  ('BKN', 'Brooklyn Nets', 'Nets', 'Brooklyn'),
  ('NYK', 'New York Knicks', 'Knicks', 'New York'),
  ('PHI', 'Philadelphia 76ers', '76ers', 'Philadelphia'),
  ('TOR', 'Toronto Raptors', 'Raptors', 'Toronto'),
  
  -- Eastern Conference - Central Division
  ('CHI', 'Chicago Bulls', 'Bulls', 'Chicago'),
  ('CLE', 'Cleveland Cavaliers', 'Cavaliers', 'Cleveland'),
  ('DET', 'Detroit Pistons', 'Pistons', 'Detroit'),
  ('IND', 'Indiana Pacers', 'Pacers', 'Indiana'),
  ('MIL', 'Milwaukee Bucks', 'Bucks', 'Milwaukee'),
  
  -- Eastern Conference - Southeast Division
  ('ATL', 'Atlanta Hawks', 'Hawks', 'Atlanta'),
  ('CHA', 'Charlotte Hornets', 'Hornets', 'Charlotte'),
  ('MIA', 'Miami Heat', 'Heat', 'Miami'),
  ('ORL', 'Orlando Magic', 'Magic', 'Orlando'),
  ('WAS', 'Washington Wizards', 'Wizards', 'Washington'),
  
  -- Western Conference - Northwest Division
  ('DEN', 'Denver Nuggets', 'Nuggets', 'Denver'),
  ('MIN', 'Minnesota Timberwolves', 'Timberwolves', 'Minnesota'),
  ('OKC', 'Oklahoma City Thunder', 'Thunder', 'Oklahoma City'),
  ('POR', 'Portland Trail Blazers', 'Trail Blazers', 'Portland'),
  ('UTA', 'Utah Jazz', 'Jazz', 'Utah'),
  
  -- Western Conference - Pacific Division
  ('GSW', 'Golden State Warriors', 'Warriors', 'Golden State'),
  ('LAC', 'Los Angeles Clippers', 'Clippers', 'Los Angeles'),
  ('LAL', 'Los Angeles Lakers', 'Lakers', 'Los Angeles'),
  ('PHX', 'Phoenix Suns', 'Suns', 'Phoenix'),
  ('SAC', 'Sacramento Kings', 'Kings', 'Sacramento'),
  
  -- Western Conference - Southwest Division
  ('DAL', 'Dallas Mavericks', 'Mavericks', 'Dallas'),
  ('HOU', 'Houston Rockets', 'Rockets', 'Houston'),
  ('MEM', 'Memphis Grizzlies', 'Grizzlies', 'Memphis'),
  ('NOP', 'New Orleans Pelicans', 'Pelicans', 'New Orleans'),
  ('SAS', 'San Antonio Spurs', 'Spurs', 'San Antonio')
ON CONFLICT (abbreviation) DO NOTHING;

-- KROK 7: Utwórz funkcje pomocnicze
-- ============================================

-- Funkcja do automatycznej aktualizacji updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger dla tabeli games
CREATE TRIGGER update_games_updated_at
  BEFORE UPDATE ON public.games
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger dla tabeli odds
CREATE TRIGGER update_odds_updated_at
  BEFORE UPDATE ON public.odds
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- KROK 8: Utwórz widoki (views) dla ułatwienia zapytań
-- ============================================

-- Widok: Aktualne mecze z kursami
CREATE OR REPLACE VIEW public.current_games_with_odds AS
SELECT 
  g.id,
  g.commence_time,
  g.home_team,
  g.away_team,
  COUNT(DISTINCT o.bookmaker_key) as bookmaker_count,
  MIN(o.last_update) as oldest_odds,
  MAX(o.last_update) as newest_odds
FROM public.games g
LEFT JOIN public.odds o ON g.id = o.game_id
WHERE g.commence_time > now()
GROUP BY g.id, g.commence_time, g.home_team, g.away_team
ORDER BY g.commence_time;

-- Widok: Najlepsze kursy dla każdego meczu
CREATE OR REPLACE VIEW public.best_odds_per_game AS
SELECT DISTINCT ON (game_id, market_type, team)
  game_id,
  bookmaker_title,
  market_type,
  team,
  point,
  price,
  last_update
FROM public.odds
ORDER BY game_id, market_type, team, price DESC;

-- KROK 9: Dodaj komentarze do tabel
-- ============================================

COMMENT ON TABLE public.teams IS 'Tabela zawierająca wszystkie drużyny NBA';
COMMENT ON TABLE public.games IS 'Tabela zawierająca mecze NBA pobrane z The Odds API';
COMMENT ON TABLE public.odds IS 'Tabela zawierająca kursy bukmacherskie dla meczów NBA';

COMMENT ON COLUMN public.teams.abbreviation IS 'Skrót drużyny (np. CHI, LAL)';
COMMENT ON COLUMN public.games.commence_time IS 'Data i godzina rozpoczęcia meczu';
COMMENT ON COLUMN public.odds.market_type IS 'Typ zakładu: h2h (zwycięzca), spread (handicap), totals (over/under)';
COMMENT ON COLUMN public.odds.price IS 'Kurs w formacie decimalnym';

-- KROK 10: Weryfikacja instalacji
-- ============================================

DO $$
DECLARE
  teams_count integer;
  tables_count integer;
BEGIN
  -- Sprawdź liczbę drużyn
  SELECT COUNT(*) INTO teams_count FROM public.teams;
  
  -- Sprawdź liczbę tabel
  SELECT COUNT(*) INTO tables_count 
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name IN ('teams', 'games', 'odds');
  
  -- Wyświetl podsumowanie
  RAISE NOTICE '✅ Instalacja zakończona pomyślnie!';
  RAISE NOTICE '📊 Utworzono % tabel', tables_count;
  RAISE NOTICE '🏀 Dodano % drużyn NBA', teams_count;
  RAISE NOTICE '🔐 RLS włączony dla wszystkich tabel';
  RAISE NOTICE '📈 Utworzono indeksy i triggery';
  RAISE NOTICE '👁️  Utworzono widoki pomocnicze';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Możesz teraz uruchomić backend aplikacji!';
END $$;

-- Pokaż strukturę tabel
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('teams', 'games', 'odds')
ORDER BY table_name;

-- Pokaż drużyny
SELECT abbreviation, full_name, city 
FROM public.teams 
ORDER BY city;

-- ============================================
-- KONIEC SKRYPTU
-- ============================================
