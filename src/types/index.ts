// Type definitions for NBA Analysis Application
import { ComponentType } from 'react';

export interface GameData {
  id: string;
  home_team: string;
  away_team: string;
  game_date: string;
  status: 'scheduled' | 'live' | 'finished';
  home_score?: number;
  away_score?: number;
}

export interface OddsData {
  id: string;
  game_id: string;
  sportsbook: string;
  home_odds: number;
  away_odds: number;
  total_over: number;
  total_under: number;
  total_points: number;
  timestamp: string;
}

export interface BettingRecommendation {
  selection: string;
  odds: number;
  stake: number;
  confidence: number;
  reasoning: string;
  sportsbook: string;
  kelly_percentage: number;
}

export interface BullsAnalysis {
  last_game_recap: {
    opponent: string;
    result: string;
    key_performances: string[];
    team_stats: string;
    concerns: string;
  };
  current_form_analysis: {
    record_l10: string;
    ats_l10: string;
    home_record: string;
    vs_west: string;
    clutch_record: string;
  };
  player_projections: {
    [playerName: string]: {
      pts: number;
      reb: number;
      ast: number;
      betting_props: string;
    };
  };
}

export interface ReportData {
  timestamp: string;
  report_type: string;
  [key: string]: any;
}

export interface PerformanceMetrics {
  roi: number;
  total_bets: number;
  win_rate: number;
  total_profit: number;
  total_wagered: number;
  avg_bet_size: number;
}

export interface ArbitrageOpportunity {
  game: string;
  profit_margin: number;
  home_bet: {
    sportsbook: string;
    odds: number;
    allocation: number;
  };
  away_bet: {
    sportsbook: string;
    odds: number;
    allocation: number;
  };
}

export interface KellyCalculation {
  kelly_fraction: number;
  percentage: number;
  recommended_stake: string;
}

// Component Props
export interface NavItem {
  id: string;
  label: string;
  icon: ComponentType;
}

export interface LoadingState {
  isLoading: boolean;
  error?: string;
}

// API Response Types
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
}

// Section Types
export type SectionType = 
  | 'dashboard' 
  | 'reports' 
  | 'bulls-analysis' 
  | 'betting-recommendations' 
  | 'live-odds';

// Configuration
export interface AppConfig {
  API_BASE_URL: string;
  REFRESH_INTERVAL: number;
  TIMEZONE: string;
}