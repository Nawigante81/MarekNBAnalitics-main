-- ============================================
-- PROSTY SETUP BAZY DANYCH NBA - SUPABASE
-- Skopiuj i wklej cały kod do SQL Editor
-- ============================================

-- 1. USUŃ STARE TABELE (jeśli istnieją)
DROP TABLE IF EXISTS public.odds CASCADE;
DROP TABLE IF EXISTS public.games CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;

-- 2. UTWÓRZ TABELE

-- Tabela: teams
CREATE TABLE public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  abbreviation text UNIQUE NOT NULL,
  full_name text NOT NULL,
  name text NOT NULL,
  city text,
  created_at timestamptz DEFAULT now()
);

-- Tabela: games
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

-- Tabela: odds
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

-- 3. UTWÓRZ INDEKSY
CREATE INDEX idx_teams_abbreviation ON public.teams(abbreviation);
CREATE INDEX idx_games_commence_time ON public.games(commence_time);
CREATE INDEX idx_odds_game_id ON public.odds(game_id);
CREATE INDEX idx_odds_bookmaker_key ON public.odds(bookmaker_key);
CREATE INDEX idx_odds_market_type ON public.odds(market_type);

-- 4. WŁĄCZ RLS I USTAW POLITYKI (pełny dostęp)
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON public.teams FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.games FOR ALL USING (true);
CREATE POLICY "Allow all" ON public.odds FOR ALL USING (true);

-- 5. DODAJ 30 DRUŻYN NBA
INSERT INTO public.teams (abbreviation, full_name, name, city) VALUES
  ('BOS', 'Boston Celtics', 'Celtics', 'Boston'),
  ('BKN', 'Brooklyn Nets', 'Nets', 'Brooklyn'),
  ('NYK', 'New York Knicks', 'Knicks', 'New York'),
  ('PHI', 'Philadelphia 76ers', '76ers', 'Philadelphia'),
  ('TOR', 'Toronto Raptors', 'Raptors', 'Toronto'),
  ('CHI', 'Chicago Bulls', 'Bulls', 'Chicago'),
  ('CLE', 'Cleveland Cavaliers', 'Cavaliers', 'Cleveland'),
  ('DET', 'Detroit Pistons', 'Pistons', 'Detroit'),
  ('IND', 'Indiana Pacers', 'Pacers', 'Indiana'),
  ('MIL', 'Milwaukee Bucks', 'Bucks', 'Milwaukee'),
  ('ATL', 'Atlanta Hawks', 'Hawks', 'Atlanta'),
  ('CHA', 'Charlotte Hornets', 'Hornets', 'Charlotte'),
  ('MIA', 'Miami Heat', 'Heat', 'Miami'),
  ('ORL', 'Orlando Magic', 'Magic', 'Orlando'),
  ('WAS', 'Washington Wizards', 'Wizards', 'Washington'),
  ('DEN', 'Denver Nuggets', 'Nuggets', 'Denver'),
  ('MIN', 'Minnesota Timberwolves', 'Timberwolves', 'Minnesota'),
  ('OKC', 'Oklahoma City Thunder', 'Thunder', 'Oklahoma City'),
  ('POR', 'Portland Trail Blazers', 'Trail Blazers', 'Portland'),
  ('UTA', 'Utah Jazz', 'Jazz', 'Utah'),
  ('GSW', 'Golden State Warriors', 'Warriors', 'Golden State'),
  ('LAC', 'Los Angeles Clippers', 'Clippers', 'Los Angeles'),
  ('LAL', 'Los Angeles Lakers', 'Lakers', 'Los Angeles'),
  ('PHX', 'Phoenix Suns', 'Suns', 'Phoenix'),
  ('SAC', 'Sacramento Kings', 'Kings', 'Sacramento'),
  ('DAL', 'Dallas Mavericks', 'Mavericks', 'Dallas'),
  ('HOU', 'Houston Rockets', 'Rockets', 'Houston'),
  ('MEM', 'Memphis Grizzlies', 'Grizzlies', 'Memphis'),
  ('NOP', 'New Orleans Pelicans', 'Pelicans', 'New Orleans'),
  ('SAS', 'San Antonio Spurs', 'Spurs', 'San Antonio');

-- 6. SPRAWDŹ INSTALACJĘ
SELECT 'Utworzono tabele:' as info, COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('teams', 'games', 'odds')
UNION ALL
SELECT 'Dodano drużyn:', COUNT(*) FROM public.teams;

-- GOTOWE! ✅
