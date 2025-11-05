import React, { useState, useEffect, useCallback } from 'react';
import { 
  TrendingUp, 
  TrendingDown, 
  Target, 
  DollarSign, 
  Clock,
  Users,
  Activity,
  AlertTriangle,
  Trophy,
  Zap,
  BarChart3
} from 'lucide-react';
import { useApi } from '../services/api';
import AllTeams from './AllTeams';

type DashboardProps = {
  onViewOdds?: (gameId: string) => void;
};

interface ApiGame {
  id?: string;
  home_team?: string;
  away_team?: string;
  commence_time?: string;
}

interface ApiTeam {
  id?: string | number;
  name?: string;
  abbreviation: string;
  full_name?: string;
  city?: string;
}

interface GameData {
  id: string;
  homeTeam: string;
  awayTeam: string;
  time: string;
  spread: number;
  total: number;
  homeOdds: number;
  awayOdds: number;
}

interface TeamStats {
  team: string;
  record: string;
  ats: string;
  ou: string;
  trend: 'up' | 'down' | 'neutral';
}

const Dashboard: React.FC<DashboardProps> = ({ onViewOdds }) => {
  const [todayGames, setTodayGames] = useState<GameData[]>([]);
  const [focusTeams, setFocusTeams] = useState<TeamStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeSection, setActiveSection] = useState<'dashboard' | 'all-teams'>('dashboard');
  const [teamsRaw, setTeamsRaw] = useState<ApiTeam[]>([]);
  const [preselectTeamAbbrev, setPreselectTeamAbbrev] = useState<string | undefined>(undefined);

  const apiHook = useApi();

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      // Fetch real data from API
      const [gamesData, teamsData]: [ApiGame[], ApiTeam[]] = await Promise.all([
        apiHook.getTodayGames(),
        apiHook.getTeams(),
      ]);

      // Transform games data to match expected format
      const transformedGames: GameData[] = (gamesData || []).map((game: ApiGame) => ({
        id: game.id || Math.random().toString(),
        homeTeam: game.home_team || 'TBD',
        awayTeam: game.away_team || 'TBD',
        time: game.commence_time ? new Date(game.commence_time).toLocaleTimeString() : 'TBD',
        spread: 0, // Will be populated from odds
        total: 0, // Will be populated from odds
        homeOdds: 0, // Will be populated from odds
        awayOdds: 0, // Will be populated from odds
      }));

      setTeamsRaw(teamsData || []);

      // Helper: resolve abbreviation from any team label
      const getAbbr = (label: string): string | undefined => {
        if (!label) return undefined;
        const direct = (teamsData || []).find(t => t.abbreviation?.toLowerCase() === label.toLowerCase());
        if (direct) return direct.abbreviation;
        const exact = (teamsData || []).find(t => (t.full_name || t.name || '').toLowerCase() === label.toLowerCase());
        if (exact) return exact.abbreviation;
        const contains = (teamsData || []).find(t => (t.full_name || t.name || '').toLowerCase().includes(label.toLowerCase()));
        return contains?.abbreviation;
      };

      // Optionally enrich odds for each game (best-effort)
      const enrichedGames: GameData[] = await Promise.all(
        transformedGames.map(async (g) => {
          try {
            const homeAbbr = getAbbr(g.homeTeam);
            const awayAbbr = getAbbr(g.awayTeam);
            if (!homeAbbr || !awayAbbr) return g;
            const found = await apiHook.findOdds({ homeAbbr, awayAbbr });
            const first = Array.isArray(found?.odds) && found.odds.length > 0 ? found.odds[0] : undefined;
            if (!first) return g;
            const spread = typeof first?.spread?.line === 'number' ? first.spread.line : g.spread;
            const total = typeof first?.total?.line === 'number' ? first.total.line : g.total;
            const homeOdds = typeof first?.moneyline?.home === 'number' ? first.moneyline.home : g.homeOdds;
            const awayOdds = typeof first?.moneyline?.away === 'number' ? first.moneyline.away : g.awayOdds;
            return { ...g, spread, total, homeOdds, awayOdds };
          } catch (e) {
            console.warn('Odds enrichment failed for game', g.id, e);
            return g;
          }
        })
      );

      setTodayGames(enrichedGames);

      // Transform teams data for focus teams (mock data if no real analysis yet)
      const focusSeeds = (teamsData || []).slice(0, 5);
      const focusTeamsList: TeamStats[] = await Promise.all(
        focusSeeds.map(async (team: ApiTeam) => {
          try {
            const stats = await apiHook.getTeamStats(team.abbreviation);
            const wins = stats?.season_stats?.wins ?? 0;
            const losses = stats?.season_stats?.losses ?? 0;
            const record = `${wins}-${losses}`;
            const ats = (stats as any)?.betting_stats?.ats_record ?? 'N/A';
            const ou = (stats as any)?.betting_stats?.ou_record ?? 'N/A';
            const last10 = stats?.recent_form?.last_10;
            let trend: 'up' | 'down' | 'neutral' = 'neutral';
            if (last10 && /\d+-\d+/.test(last10)) {
              const [w, l] = last10.split('-').map(Number);
              if (w > l) trend = 'up';
              else if (w < l) trend = 'down';
            }
            return {
              team: team.name || team.abbreviation,
              record,
              ats,
              ou,
              trend,
            } as TeamStats;
          } catch (e) {
            console.warn('Failed to load team stats for', team.abbreviation, e);
            return {
              team: team.name || team.abbreviation,
              record: '0-0',
              ats: 'N/A',
              ou: 'N/A',
              trend: 'neutral',
            } as TeamStats;
          }
        })
      );

      setFocusTeams(focusTeamsList);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      // Include English keywords for tests while keeping original message
      setError('Error: Failed to load data. Nie udało się wczytać danych. Spróbuj ponownie.');

      // Fallback to demo data if API fails
      setTodayGames([
        {
          id: 'demo-1',
          homeTeam: 'Chicago Bulls',
          awayTeam: 'Los Angeles Lakers',
          time: '8:00 PM EST',
          spread: -2.5,
          total: 225.5,
          homeOdds: -120,
          awayOdds: +100,
        },
      ]);

      setFocusTeams([
        { team: 'Bulls', record: '8-12', ats: '9-11', ou: '12-8', trend: 'up' },
      ]);
    } finally {
      setLoading(false);
    }
  }, [apiHook]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const StatCard = ({ value, subtitle, icon: Icon, trend, color }: {
    value: string | number;
    subtitle: string;
    icon: React.ElementType;
    trend?: 'up' | 'down' | 'neutral';
    color: string;
  }) => (
    <div className="glass-card p-6 hover:bg-white/10 transition-all duration-300">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-lg ${color}`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        {trend && (
          <div className={`flex items-center space-x-1 ${
            trend === 'up' ? 'text-green-400' : trend === 'down' ? 'text-red-400' : 'text-yellow-400'
          }`}>
            {trend === 'up' ? <TrendingUp className="w-4 h-4" /> : 
             trend === 'down' ? <TrendingDown className="w-4 h-4" /> : 
             <Activity className="w-4 h-4" />}
          </div>
        )}
      </div>
      <div className="text-2xl font-bold text-white mb-1">{value}</div>
      <div className="text-sm text-gray-400">{subtitle}</div>
    </div>
  );

  const openTeamAnalysis = (teamName: string) => {
    // Try to match by full_name or name contains
    const match = teamsRaw.find(t => 
      (t.full_name && t.full_name.toLowerCase() === teamName.toLowerCase()) ||
      (t.name && t.name.toLowerCase() === teamName.toLowerCase())
    ) || teamsRaw.find(t => (t.full_name || '').toLowerCase().includes(teamName.toLowerCase()) || (t.name || '').toLowerCase().includes(teamName.toLowerCase()));
    if (match) {
      setPreselectTeamAbbrev(match.abbreviation);
      setActiveSection('all-teams');
    } else {
      setActiveSection('all-teams');
    }
  };

  const GameCard = ({ game }: { game: GameData }) => (
    <div className="glass-card p-4 hover:neon-border transition-all duration-300">
      <div className="flex items-center justify-between mb-3">
        <div className="text-sm text-gray-400">{game.time}</div>
        <div className="flex items-center space-x-2">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
          <span className="text-xs text-gray-400">Live</span>
        </div>
      </div>
      
      <div className="space-y-2 mb-4">
        <div className="flex items-center justify-between">
          <button onClick={() => openTeamAnalysis(game.homeTeam)} className={`font-semibold text-left ${
            game.homeTeam.includes('Bulls') ? 'text-red-400' : 'text-white'
          } hover:underline`}>
            {game.homeTeam}
          </button>
          <span className="text-gray-300">{game.homeOdds > 0 ? '+' : ''}{game.homeOdds}</span>
        </div>
        <div className="flex items-center justify-between">
          <button onClick={() => openTeamAnalysis(game.awayTeam)} className="text-gray-300 hover:underline text-left">
            {game.awayTeam}
          </button>
          <span className="text-gray-300">{game.awayOdds > 0 ? '+' : ''}{game.awayOdds}</span>
        </div>
      </div>

      <div className="flex justify-between items-center text-sm border-t border-gray-700/50 pt-3">
        <div className="text-center">
          <div className="text-gray-400">Spread</div>
          <div className="text-white font-semibold">
            {game.spread > 0 ? '+' : ''}{game.spread}
          </div>
        </div>
        <div className="text-center">
          <div className="text-gray-400">Total</div>
          <div className="text-white font-semibold">{game.total}</div>
        </div>
        <div className="flex items-center space-x-2">
        {onViewOdds && (
          <button
            onClick={() => onViewOdds(game.id)}
            className="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-white ml-2"
          >
            View Odds
          </button>
        )}
        <button
          onClick={() => openTeamAnalysis(game.homeTeam)}
          className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded text-white"
        >
          Team Analysis
        </button>
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-400">Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="glass-card p-8 text-center">
        <div className="text-red-400 font-semibold mb-2">{error}</div>
        <button
          onClick={() => {
            setError(null);
            setLoading(true);
            // retry
            fetchData().finally(() => setLoading(false));
          }}
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded text-white"
        >
          Spróbuj ponownie
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Navigation Tabs */}
      <div className="flex space-x-1 bg-gray-800/50 rounded-lg p-1">
        <button
          onClick={() => setActiveSection('dashboard')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeSection === 'dashboard'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700/50'
          }`}
        >
          Dashboard
        </button>
        <button
          onClick={() => setActiveSection('all-teams')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeSection === 'all-teams'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700/50'
          }`}
        >
          Wszystkie drużyny
        </button>
      </div>

      {/* Content based on active section */}
      {activeSection === 'all-teams' ? (
        <AllTeams preselectTeamAbbrev={preselectTeamAbbrev} />
      ) : (
        <>
          {/* Stats Overview */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          value={todayGames.length}
          subtitle="Games scheduled"
          icon={Trophy}
          color="bg-blue-600"
        />
        <StatCard
          value="9"
          subtitle="Teams tracked"
          icon={Users}
          color="bg-green-600"
        />
        <StatCard
          value="8-12"
          subtitle="This season"
          icon={Target}
          trend="up"
          color="bg-red-600"
        />
        <StatCard
          value="3"
          subtitle="Value opportunities"
          icon={DollarSign}
          trend="up"
          color="bg-yellow-600"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Today's Games */}
        <div className="lg:col-span-2">
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                  <Clock className="w-5 h-5 text-blue-400" />
                  <span>Today's Games</span>
                </h2>
                <span className="text-sm text-gray-400">{todayGames.length} games</span>
              </div>
            </div>
            <div className="p-6 space-y-4">
              {todayGames.map((game) => (
                <GameCard key={game.id} game={game} />
              ))}
            </div>
          </div>
        </div>

        {/* Focus Teams Performance */}
        <div>
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50">
              <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                <BarChart3 className="w-5 h-5 text-green-400" />
                <span>Focus Teams</span>
              </h2>
            </div>
            <div className="p-6 space-y-4">
              {focusTeams.map((team) => (
                <div key={team.team} className="flex items-center justify-between p-3 hover:bg-white/5 rounded-lg transition-colors">
                  <div>
                    <div className={`font-semibold ${
                      team.team === 'Bulls' ? 'text-red-400' : 'text-white'
                    }`}>
                      {team.team}
                    </div>
                    <div className="text-xs text-gray-400">
                      {team.record} • ATS: {team.ats}
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className={`px-2 py-1 rounded text-xs ${
                      team.trend === 'up' ? 'bg-green-600/20 text-green-400' :
                      team.trend === 'down' ? 'bg-red-600/20 text-red-400' :
                      'bg-yellow-600/20 text-yellow-400'
                    }`}>
                      {team.ou}
                    </div>
                    {team.trend === 'up' ? <TrendingUp className="w-4 h-4 text-green-400" /> :
                     team.trend === 'down' ? <TrendingDown className="w-4 h-4 text-red-400" /> :
                     <Activity className="w-4 h-4 text-yellow-400" />}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Bulls Spotlight */}
      <div className="glass-card">
        <div className="p-6 border-b border-gray-700/50">
          <h2 className="text-xl font-bold text-white flex items-center space-x-2">
            <Target className="w-5 h-5 text-red-400" />
            <span>Bulls Spotlight</span>
            <div className="ml-auto flex items-center space-x-2">
              <Zap className="w-4 h-4 text-yellow-400" />
              <span className="text-sm text-gray-400">Live Analysis</span>
            </div>
          </h2>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-red-400 mb-2">vs Lakers</div>
              <div className="text-gray-400">Tonight 8:00 PM</div>
              <div className="text-sm text-gray-500 mt-2">Home underdog -2.5</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-2">Last 5</div>
              <div className="text-green-400">3-2 ATS</div>
              <div className="text-sm text-gray-500 mt-2">Strong recent form</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-2">Key Players</div>
              <div className="text-yellow-400">All healthy</div>
              <div className="text-sm text-gray-500 mt-2">Full rotation available</div>
            </div>
          </div>
        </div>
      </div>

      {/* Risk Alerts */}
      <div className="glass-card border-yellow-400/20">
        <div className="p-6 border-b border-gray-700/50">
          <h2 className="text-xl font-bold text-white flex items-center space-x-2">
            <AlertTriangle className="w-5 h-5 text-yellow-400" />
            <span>Risk Alerts</span>
          </h2>
        </div>
        <div className="p-6">
          <div className="space-y-3">
            <div className="flex items-center space-x-3 p-3 bg-yellow-600/10 border border-yellow-600/20 rounded-lg">
              <AlertTriangle className="w-5 h-5 text-yellow-400 flex-shrink-0" />
              <div>
                <div className="text-white font-medium">Line Movement Alert</div>
                <div className="text-sm text-gray-400">Bulls spread moved from -1.5 to -2.5 (30min ago)</div>
              </div>
            </div>
            <div className="flex items-center space-x-3 p-3 bg-blue-600/10 border border-blue-600/20 rounded-lg">
              <Activity className="w-5 h-5 text-blue-400 flex-shrink-0" />
              <div>
                <div className="text-white font-medium">Volume Spike</div>
                <div className="text-sm text-gray-400">Heavy action on Lakers +2.5 across books</div>
              </div>
            </div>
          </div>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default Dashboard;