// API Service Layer for NBA Analytics Frontend
// Handles all communication with the FastAPI backend

import { useMemo } from 'react';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

// Generic API request helper with error handling
async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE}${endpoint}`;

  const config: RequestInit = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  };

  const response = await fetch(url, config);
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API Error ${response.status}: ${errorText || response.statusText}`);
  }
  return response.json();
}

// ===== Types =====
export interface TeamSummary {
  id?: string | number;
  abbreviation: string;
  full_name?: string;
  name?: string;
  city?: string;
  conference?: 'Eastern' | 'Western' | string;
  division?: string;
}

export interface TeamSeasonStats {
  wins: number;
  losses: number;
  win_percentage: number;
  points_per_game?: number;
  points_allowed?: number;
  offensive_rating?: number;
  defensive_rating?: number;
  net_rating?: number;
}

export interface TeamStatsResponse extends TeamSummary {
  season_stats: TeamSeasonStats;
  recent_form?: { last_10?: string };
  betting_stats?: { avg_total?: number };
  last_updated?: string;
}

export interface LiveOddsBookmaker {
  name: string;
  moneyline: { home?: number; away?: number };
  spread: { line?: number; home?: number; away?: number };
  total: { line?: number; over?: number; under?: number };
}

export interface LiveOddsGame {
  gameId: string;
  homeTeam: string;
  awayTeam: string;
  startTime: string;
  bookmakers: LiveOddsBookmaker[];
}

// Time series types
export interface TeamTimeSeriesPoint {
  date: string;
  ppg: number;
  papg: number;
  net: number;
  margin: number;
}

export interface TeamTimeSeriesResponse {
  team: string;
  series: TeamTimeSeriesPoint[];
  count: number;
}

// Team schedule/result types
export interface TeamNextGameResponse {
  team: string;
  abbr: string;
  opponent?: string;
  opponent_abbr?: string;
  commence_time?: string;
  home?: boolean;
  next_game?: null; // when not found
}

export interface TeamLastGameResponse {
  team: string;
  abbr: string;
  opponent?: string;
  opponent_abbr?: string;
  date?: string;
  home?: boolean;
  team_score?: number;
  opp_score?: number;
  result?: 'W' | 'L';
  last_game?: null; // when not found
}

// ===== Teams API =====
export const teamsApi = {
  getAll: () => apiRequest<{ teams: TeamSummary[] }>("/api/teams"),

  getAllAnalysis: () =>
    apiRequest<{
      teams: TeamStatsResponse[];
      count: number;
      conferences: { Eastern: TeamStatsResponse[]; Western: TeamStatsResponse[] };
    }>("/api/teams/analysis"),

  getPlayers: (teamAbbrev: string) =>
    apiRequest<{ team: string; players: any[]; count: number }>(
      `/api/teams/${teamAbbrev}/players`
    ),

  getAnalysis: (teamAbbrev: string) =>
    apiRequest<TeamStatsResponse | any>(`/api/teams/${teamAbbrev}/analysis`),

  getStats: (teamAbbrev: string, season?: string): Promise<TeamStatsResponse> => {
    const params = new URLSearchParams();
    if (season) params.set("season", season);
    const query = params.toString() ? `?${params}` : "";
    return apiRequest<TeamStatsResponse>(
      `/api/teams/${teamAbbrev}/stats${query}`
    );
  },

  compare: (team1: string, team2: string, team3?: string) => {
    const params = new URLSearchParams({ team1, team2 });
    if (team3) params.append("team3", team3);
    return apiRequest<any>(`/api/teams/compare?${params}`);
  },

  getTimeSeries: (
    teamAbbrev: string,
    metric: "ppg" | "papg" | "net" | "margin" = "net",
    games: number = 20
  ) => {
    const params = new URLSearchParams();
    if (metric) params.set("metric", metric);
    if (games) params.set("games", String(games));
    const query = params.toString() ? `?${params}` : "";
    return apiRequest<TeamTimeSeriesResponse>(
      `/api/teams/${teamAbbrev}/timeseries${query}`
    );
  },

  getNextGame: (teamAbbrev: string) =>
    apiRequest<TeamNextGameResponse>(`/api/teams/${teamAbbrev}/next-game`),

  getLastGame: (teamAbbrev: string) =>
    apiRequest<TeamLastGameResponse>(`/api/teams/${teamAbbrev}/last-game`),
};

// ===== Players API =====
export const playersApi = {
  getAll: (filters?: { team?: string; position?: string; active?: boolean }) => {
    const params = new URLSearchParams();
    if (filters?.team) params.set("team", filters.team);
    if (filters?.position) params.set("position", filters.position);
    if (filters?.active !== undefined)
      params.set("active", filters.active.toString());

    const query = params.toString() ? `?${params}` : "";
    return apiRequest<{ players: any[]; count: number }>(
      `/api/players${query}`
    );
  },

  getById: (playerId: string) =>
    apiRequest<{ player: any }>(`/api/players/${playerId}`),

  getStats: (playerId: string, season?: string) => {
    const params = new URLSearchParams();
    if (season) params.set("season", season);
    const query = params.toString() ? `?${params}` : "";
    return apiRequest<{ player: any; stats: any; season: string }>(
      `/api/players/${playerId}/stats${query}`
    );
  },

  searchByName: (name: string) =>
    apiRequest<{ query: string; players: any[]; count: number }>(
      `/api/players/search/${name}`
    ),
};

// ===== Games API =====
export const gamesApi = {
  getToday: () => apiRequest<{ games: any[] }>("/api/games/today"),

  getOdds: (gameId: string) => apiRequest<{ odds: any[] }>(`/api/odds/${gameId}`),

  getLiveOdds: () =>
    apiRequest<{ games: any[]; count: number; timestamp: string }>(
      "/api/live-odds"
    ),

  findOdds: (params: {
    homeAbbr?: string;
    awayAbbr?: string;
    date?: string;
    slug?: string;
  }) => {
    const q = new URLSearchParams();
    if (params.homeAbbr) q.set("home_abbr", params.homeAbbr);
    if (params.awayAbbr) q.set("away_abbr", params.awayAbbr);
    if (params.date) q.set("date", params.date);
    if (params.slug) q.set("slug", params.slug);
    const query = q.toString() ? `?${q.toString()}` : "";
    return apiRequest<{ game: LiveOddsGame | null; odds: any[]; source: string; note?: string }>(
      `/api/odds/find${query}`
    );
  },
};

// ===== Reports API =====
export const reportsApi = {
  get750Report: () => apiRequest<any>("/api/reports/750am"),
  get800Report: () => apiRequest<any>("/api/reports/800am"),
  get1100Report: () => apiRequest<any>("/api/reports/1100am"),
};

// ===== Bulls Analysis API =====
export const bullsApi = {
  getAnalysis: () => apiRequest<any>("/api/bulls-analysis"),
};

// ===== Betting API =====
export const bettingApi = {
  getRecommendations: () => apiRequest<any>("/api/betting-recommendations"),
  getArbitrageOpportunities: () =>
    apiRequest<{ opportunities: any[]; count: number }>(
      "/api/arbitrage-opportunities"
    ),
  calculateKelly: (estimatedProb: number, decimalOdds: number) =>
    apiRequest<{ kelly_fraction: number; percentage: number; recommended_stake: string }>(
      `/api/kelly-calculator?estimated_prob=${estimatedProb}&decimal_odds=${decimalOdds}`
    ),
  getPerformanceMetrics: () => apiRequest<any>("/api/performance-metrics"),
  generateBettingSlip: (bets: any[], totalStake: number = 100) =>
    apiRequest<any>("/api/betting-slip", {
      method: "POST",
      body: JSON.stringify({ bets, total_stake: totalStake }),
    }),
};

// ===== AI API =====
export const aiApi = {
  analyzeTeam: (teamAbbrev: string, focus?: string) =>
    apiRequest<{ team: string; abbr: string; analysis: string; model: string }>(
      "/api/ai/analysis",
      {
        method: "POST",
        body: JSON.stringify({ team_abbr: teamAbbrev, focus }),
      }
    ),
};

// ===== System API =====
export const systemApi = {
  getHealth: () => apiRequest<{ status: string; timestamp: string }>("/health"),
  getStatus: () => apiRequest<any>("/api/status"),
  triggerRosterScrape: (season: string = "2025") =>
    apiRequest<{ message: string; timestamp: string; status: string }>(
      "/api/scrape/rosters",
      {
        method: "POST",
        body: JSON.stringify({ season }),
      }
    ),
};

// Combined export
export const api = {
  teams: teamsApi,
  players: playersApi,
  games: gamesApi,
  reports: reportsApi,
  bulls: bullsApi,
  betting: bettingApi,
  ai: aiApi,
  system: systemApi,
};

// Hook wrapper for common flows and test-friendly behavior
export function useApi() {
  return useMemo(
    () => ({
      async getTeams() {
        const response = await api.teams.getAll();
        return response.teams || [];
      },

      async getTodayGames() {
        const response = await api.games.getToday();
        return response.games || [];
      },

      async getLiveOdds() {
        try {
          return await api.games.getLiveOdds();
        } catch (error) {
          console.error("Failed to fetch live odds:", error);
          return { games: [], count: 0, timestamp: new Date().toISOString() };
        }
      },

      async getBullsPlayers() {
        try {
          const response = await api.teams.getPlayers("CHI");
          return response.players || [];
        } catch (error) {
          console.error("Failed to fetch Bulls players:", error);
          return [];
        }
      },

      async getBullsAnalysis() {
        try {
          return await api.bulls.getAnalysis();
        } catch (error) {
          console.error("Failed to fetch Bulls analysis:", error);
          return null;
        }
      },

      async getBettingRecommendations() {
        try {
          return await api.betting.getRecommendations();
        } catch (error) {
          console.error("Failed to fetch betting recommendations:", error);
          return null;
        }
      },

      async getTeamsAnalysis() {
        try {
          const teamsResponse = await api.teams.getAll();
          const teams = teamsResponse.teams || [];
          const teamsWithStats = await Promise.all(
            teams.map(async (team: any) => {
              try {
                return await api.teams.getStats(team.abbreviation);
              } catch (error) {
                console.error(`Failed to fetch stats for ${team.abbreviation}:`, error);
                return {
                  ...team,
                  conference: "Unknown",
                  division: "Unknown",
                  season_stats: { wins: 0, losses: 0, win_percentage: 0 },
                  recent_form: { last_10: "0-0" },
                  betting_stats: { ats_record: "0-0", ats_percentage: 0 },
                  strength_rating: 0,
                };
              }
            })
          );

          const eastern = teamsWithStats.filter((t: any) => t.conference === "Eastern");
          const western = teamsWithStats.filter((t: any) => t.conference === "Western");
          return {
            teams: teamsWithStats,
            count: teamsWithStats.length,
            conferences: { Eastern: eastern, Western: western },
          };
        } catch (error) {
          console.error("Failed to fetch teams analysis:", error);
          return { teams: [], count: 0, conferences: { Eastern: [], Western: [] } };
        }
      },

      async getPlayers(filters?: { team?: string; position?: string; active?: boolean }) {
        try {
          const response = await api.players.getAll(filters);
          return response.players || [];
        } catch (error) {
          console.error("Failed to fetch players:", error);
          return [];
        }
      },

      async getPlayerStats(playerId: string, season?: string) {
        try {
          return await api.players.getStats(playerId, season);
        } catch (error) {
          console.error(`Failed to fetch stats for player ${playerId}:`, error);
          return null;
        }
      },

      async getTeamStats(teamAbbrev: string, season?: string) {
        try {
          return await api.teams.getStats(teamAbbrev, season);
        } catch (error) {
          console.error(`Failed to fetch stats for team ${teamAbbrev}:`, error);
          return null;
        }
      },

      async findOdds(params: { homeAbbr?: string; awayAbbr?: string; date?: string; slug?: string }) {
        try {
          return await api.games.findOdds(params);
        } catch (error) {
          console.error("Failed to find game odds:", error);
          return { game: null, odds: [], source: "external_odds" };
        }
      },

      async getTeamTimeSeries(teamAbbrev: string, metric: "ppg" | "papg" | "net" | "margin" = "net", games: number = 20) {
        try {
          return await api.teams.getTimeSeries(teamAbbrev, metric, games);
        } catch (error) {
          console.error(`Failed to fetch time series for team ${teamAbbrev}:`, error);
          return { team: teamAbbrev, series: [], count: 0 } as TeamTimeSeriesResponse;
        }
      },

      async getAiTeamAnalysis(teamAbbrev: string, focus?: string) {
        try {
          return await api.ai.analyzeTeam(teamAbbrev, focus);
        } catch (error) {
          console.error("Failed to generate AI analysis:", error);
          return null;
        }
      },
    }),
    []
  );
}

export default api;