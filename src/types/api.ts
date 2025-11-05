// API Response Types for NBA Analytics
export interface Player {
  id: string;
  name: string;
  jersey_number?: number;
  team_id?: string;
  team_abbreviation?: string;
  position?: string;
  height?: string;
  weight?: number;
  birth_date?: string;
  experience?: number;
  college?: string;
  basketball_reference_id?: string;
  basketball_reference_url?: string;
  is_active?: boolean;
  season_year?: string;
  created_at?: string;
  updated_at?: string;
  teams?: {
    abbreviation: string;
    full_name: string;
    city: string;
    name: string;
  };
}

export interface PlayerStats {
  ppg: number;
  rpg: number;
  apg: number;
  fg_percentage: number;
  three_point_percentage: number;
  ft_percentage: number;
  steals: number;
  blocks: number;
  turnovers: number;
  minutes_per_game: number;
  games_played: number;
  field_goals_made: number;
  field_goals_attempted: number;
  three_pointers_made: number;
  three_pointers_attempted: number;
  free_throws_made: number;
  free_throws_attempted: number;
}

export interface Team {
  id: string;
  abbreviation: string;
  full_name: string;
  name: string;
  city: string;
  created_at?: string;
}

export interface TeamStats {
  wins: number;
  losses: number;
  win_percentage: number;
  points_per_game: number;
  points_allowed: number;
  offensive_rating: number;
  defensive_rating: number;
  net_rating: number;
  field_goal_percentage: number;
  three_point_percentage: number;
  free_throw_percentage: number;
  rebounds_per_game: number;
  assists_per_game: number;
  steals_per_game: number;
  blocks_per_game: number;
  turnovers_per_game: number;
}

export interface TeamForm {
  last_10: string;
  last_5: string;
  home_record: string;
  away_record: string;
  vs_conference: string;
}

export interface BettingStats {
  ats_record: string;
  ats_percentage: number;
  over_under: string;
  ou_percentage: number;
  avg_total: number;
}

export interface TeamAnalysis extends Team {
  conference: string;
  division: string;
  season_stats: TeamStats;
  recent_form: TeamForm;
  betting_stats: BettingStats;
  strength_rating: number;
  key_players?: string[];
  last_updated: string;
}

export interface Game {
  id: string;
  sport_key?: string;
  sport_title?: string;
  commence_time: string;
  home_team: string;
  away_team: string;
  created_at?: string;
  updated_at?: string;
}

export interface Bookmaker {
  name: string;
  moneyline: {
    home?: number;
    away?: number;
  };
  spread: {
    line?: number;
    home?: number;
    away?: number;
  };
  total: {
    line?: number;
    over?: number;
    under?: number;
  };
}

export interface GameOdds {
  gameId: string;
  homeTeam: string;
  awayTeam: string;
  startTime: string;
  bookmakers: Bookmaker[];
  movements?: LineMovement[];
}

export interface LineMovement {
  type: 'spread' | 'total' | 'ml';
  direction: 'up' | 'down';
  from: number;
  to: number;
  time: string;
}

export interface LiveAlert {
  id: string;
  type: 'movement' | 'value' | 'reverse';
  game: string;
  message: string;
  severity: 'high' | 'medium' | 'low';
  time: string;
}

// API Response interfaces
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
  timestamp?: string;
}

export interface PlayersResponse {
  players: Player[];
  count: number;
  total?: number;
  limit?: number;
  offset?: number;
}

export interface PlayerStatsResponse {
  player: Player;
  stats: PlayerStats;
  season: string;
  last_updated: string;
}

export interface TeamsResponse {
  teams: Team[];
  count?: number;
}

export interface TeamsAnalysisResponse {
  teams: TeamAnalysis[];
  count: number;
  conferences: {
    Eastern: TeamAnalysis[];
    Western: TeamAnalysis[];
  };
}

export interface GamesResponse {
  games: Game[];
}

export interface LiveOddsResponse {
  games: GameOdds[];
  count: number;
  timestamp: string;
}

export interface SearchPlayersResponse {
  query: string;
  players: Player[];
  count: number;
  total?: number;
  limit?: number;
  offset?: number;
}

export interface HealthResponse {
  status: string;
  timestamp: string;
}