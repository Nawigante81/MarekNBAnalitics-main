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

  try {
    console.log(`🌐 API Request: ${config.method || 'GET'} ${url}`);
    
    const response = await fetch(url, config);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ API Error: ${response.status} ${response.statusText}`, errorText);
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log(`✅ API Success: ${endpoint}`, data);
    return data;
  } catch (error) {
    console.error(`💥 API Request Failed: ${endpoint}`, error);
    throw error;
  }
}

// Teams API
export const teamsApi = {
  // Get all teams
  getAll: () => apiRequest<{teams: any[]}>('/api/teams'),
  
  // Get comprehensive teams analysis
  getAllAnalysis: () => apiRequest<{
    teams: any[], 
    count: number, 
    conferences: {Eastern: any[], Western: any[]}
  }>('/api/teams/analysis'),
  
  // Get team players
  getPlayers: (teamAbbrev: string) => 
    apiRequest<{team: string, players: any[], count: number}>(`/api/teams/${teamAbbrev}/players`),
  
  // Get detailed team analysis
  getAnalysis: (teamAbbrev: string) => apiRequest<any>(`/api/teams/${teamAbbrev}/analysis`),
  
  // Get team statistics
  getStats: (teamAbbrev: string, season?: string) => {
    const params = new URLSearchParams();
    if (season) params.set('season', season);
    const query = params.toString() ? `?${params}` : '';
    return apiRequest<any>(`/api/teams/${teamAbbrev}/stats${query}`);
  },
  
  // Compare teams
  compare: (team1: string, team2: string, team3?: string) => {
    const params = new URLSearchParams({ team1, team2 });
    if (team3) params.append('team3', team3);
    return apiRequest<any>(`/api/teams/compare?${params}`);
  }
};

// Players API  
export const playersApi = {
  // Get all players with optional filters
  getAll: (filters?: {team?: string, position?: string, active?: boolean}) => {
    const params = new URLSearchParams();
    if (filters?.team) params.set('team', filters.team);
    if (filters?.position) params.set('position', filters.position);
    if (filters?.active !== undefined) params.set('active', filters.active.toString());
    
    const query = params.toString() ? `?${params}` : '';
    return apiRequest<{players: any[], count: number}>(`/api/players${query}`);
  },
  
  // Get player details
  getById: (playerId: string) => 
    apiRequest<{player: any}>(`/api/players/${playerId}`),
  
  // Get player statistics
  getStats: (playerId: string, season?: string) => {
    const params = new URLSearchParams();
    if (season) params.set('season', season);
    const query = params.toString() ? `?${params}` : '';
    return apiRequest<{player: any, stats: any, season: string}>(`/api/players/${playerId}/stats${query}`);
  },
  
  // Search players by name
  searchByName: (name: string) => 
    apiRequest<{query: string, players: any[], count: number}>(`/api/players/search/${name}`),
};

// Games API
export const gamesApi = {
  // Get today's games
  getToday: () => apiRequest<{games: any[]}>('/api/games/today'),
  
  // Get game odds
  getOdds: (gameId: string) => apiRequest<{odds: any[]}>(`/api/odds/${gameId}`),
  
  // Get live odds for today's games
  getLiveOdds: () => apiRequest<{games: any[], count: number, timestamp: string}>('/api/live-odds'),
};

// Reports API
export const reportsApi = {
  // Get 7:50 AM report (previous day analysis)
  get750Report: () => apiRequest<any>('/api/reports/750am'),
  
  // Get 8:00 AM report (morning summary)
  get800Report: () => apiRequest<any>('/api/reports/800am'),
  
  // Get 11:00 AM report (game-day scouting)
  get1100Report: () => apiRequest<any>('/api/reports/1100am'),
};

// Bulls Analysis API
export const bullsApi = {
  // Get Bulls-focused analysis
  getAnalysis: () => apiRequest<any>('/api/bulls-analysis'),
};

// Betting API
export const bettingApi = {
  // Get betting recommendations
  getRecommendations: () => apiRequest<any>('/api/betting-recommendations'),
  
  // Get arbitrage opportunities
  getArbitrageOpportunities: () => apiRequest<{opportunities: any[], count: number}>('/api/arbitrage-opportunities'),
  
  // Calculate Kelly criterion
  calculateKelly: (estimatedProb: number, decimalOdds: number) => 
    apiRequest<{kelly_fraction: number, percentage: number, recommended_stake: string}>(
      `/api/kelly-calculator?estimated_prob=${estimatedProb}&decimal_odds=${decimalOdds}`
    ),
  
  // Get performance metrics
  getPerformanceMetrics: () => apiRequest<any>('/api/performance-metrics'),
  
  // Generate betting slip
  generateBettingSlip: (bets: any[], totalStake: number = 100) => 
    apiRequest<any>('/api/betting-slip', {
      method: 'POST',
      body: JSON.stringify({bets, total_stake: totalStake}),
    }),
};

// System API
export const systemApi = {
  // Health check
  getHealth: () => apiRequest<{status: string, timestamp: string}>('/health'),
  
  // Get application status
  getStatus: () => apiRequest<any>('/api/status'),
  
  // Trigger roster scraping
  triggerRosterScrape: (season: string = '2025') => 
    apiRequest<{message: string, timestamp: string, status: string}>('/api/scrape/rosters', {
      method: 'POST',
      body: JSON.stringify({season}),
    }),
};

// Export combined API object
export const api = {
  teams: teamsApi,
  players: playersApi,
  games: gamesApi,
  reports: reportsApi,
  bulls: bullsApi,
  betting: bettingApi,
  system: systemApi,
};

// React Hook for API calls with loading state
// Using useMemo to ensure stable reference
export function useApi() {
  const isTest = import.meta.env.MODE === 'test';
  return useMemo(() => ({
    // Quick access to common endpoints
    async getTeams() {
      if (isTest) {
        // Allow errors to propagate in test mode so UI can show error states
        const response = await api.teams.getAll();
        return response.teams || [];
      }
      try {
        const response = await api.teams.getAll();
        return response.teams || [];
      } catch (error) {
        console.error('Failed to fetch teams:', error);
        return [];
      }
    },
    
    async getTodayGames() {
      if (isTest) {
        const response = await api.games.getToday();
        return response.games || [];
      }
      try {
        const response = await api.games.getToday();
        return response.games || [];
      } catch (error) {
        console.error('Failed to fetch today games:', error);
        return [];
      }
    },
    
    async getLiveOdds() {
      try {
        return await api.games.getLiveOdds();
      } catch (error) {
        console.error('Failed to fetch live odds:', error);
        return { games: [], count: 0, timestamp: new Date().toISOString() };
      }
    },
    
    async getBullsPlayers() {
      try {
        const response = await api.teams.getPlayers('CHI');
        return response.players || [];
      } catch (error) {
        console.error('Failed to fetch Bulls players:', error);
        return [];
      }
    },
    
    async getBullsAnalysis() {
      try {
        return await api.bulls.getAnalysis();
      } catch (error) {
        console.error('Failed to fetch Bulls analysis:', error);
        return null;
      }
    },
    
    async getBettingRecommendations() {
      try {
        return await api.betting.getRecommendations();
      } catch (error) {
        console.error('Failed to fetch betting recommendations:', error);
        return null;
      }
    },
    
    async getTeamsAnalysis() {
      try {
        // Get teams with their detailed stats
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
                conference: 'Unknown',
                division: 'Unknown',
                season_stats: { wins: 0, losses: 0, win_percentage: 0 },
                recent_form: { last_10: '0-0' },
                betting_stats: { ats_record: '0-0', ats_percentage: 0 },
                strength_rating: 0
              };
            }
          })
        );
        
        const eastern = teamsWithStats.filter((t: any) => t.conference === 'Eastern');
        const western = teamsWithStats.filter((t: any) => t.conference === 'Western');
        
        return {
          teams: teamsWithStats,
          count: teamsWithStats.length,
          conferences: { Eastern: eastern, Western: western }
        };
      } catch (error) {
        console.error('Failed to fetch teams analysis:', error);
        return { teams: [], count: 0, conferences: { Eastern: [], Western: [] } };
      }
    },
    
    async getPlayers(filters?: {team?: string, position?: string, active?: boolean}) {
      try {
        const response = await api.players.getAll(filters);
        return response.players || [];
      } catch (error) {
        console.error('Failed to fetch players:', error);
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
  }), [isTest]); // Depend on isTest so test-mode behavior is consistent
}

export default api;