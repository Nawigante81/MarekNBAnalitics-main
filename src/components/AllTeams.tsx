import React, { useState, useEffect } from 'react';
import { 
  Users, 
  TrendingUp, 
  TrendingDown, 
  Filter,
  Search,
  BarChart3,
  Target,
  Activity as Globe,
  Activity as ArrowUpDown,
  Eye,
  Zap
} from 'lucide-react';
import { api } from '../services/api';

interface Team {
  id: string;
  abbreviation: string;
  full_name: string;
  name: string;
  city: string;
  conference: string;
  division: string;
  season_stats: {
    wins: number;
    losses: number;
    win_percentage: number;
    points_per_game: number;
    points_allowed: number;
    offensive_rating: number;
    defensive_rating: number;
    net_rating: number;
  };
  recent_form: {
    last_10: string;
    last_5: string;
    home_record: string;
    away_record: string;
    vs_conference: string;
  };
  betting_stats: {
    ats_record: string;
    ats_percentage: number;
    over_under: string;
    ou_percentage: number;
    avg_total: number;
  };
  strength_rating: number;
  key_players: string[];
}

interface AllTeamsProps {
  onTeamSelect?: (team: Team) => void;
  preselectTeamAbbrev?: string;
}

const AllTeams: React.FC<AllTeamsProps> = ({ onTeamSelect, preselectTeamAbbrev }) => {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedConference, setSelectedConference] = useState<string>('All');
  const [selectedDivision, setSelectedDivision] = useState<string>('All');
  const [sortBy, setSortBy] = useState<string>('win_percentage');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');
  const [selectedTeam, setSelectedTeam] = useState<Team | null>(null);

  useEffect(() => {
    const fetchTeams = async () => {
      try {
        setLoading(true);
        
        // Get basic teams data
        const teamsResponse = await api.teams.getAll();
        const basicTeams = teamsResponse.teams || [];
        
        // Fetch detailed stats for each team
        const teamsWithStats = await Promise.all(
          basicTeams.map(async (team: any) => {
            try {
              const statsResponse = await api.teams.getStats(team.abbreviation);
              return statsResponse;
            } catch (error) {
              console.error(`Error fetching stats for team ${team.abbreviation}:`, error);
              // Return basic team data if stats fetch fails
              return {
                ...team,
                conference: 'Unknown',
                division: 'Unknown',
                season_stats: {
                  wins: 0,
                  losses: 0,
                  win_percentage: 0,
                  points_per_game: 0,
                  points_allowed: 0,
                  offensive_rating: 0,
                  defensive_rating: 0,
                  net_rating: 0
                },
                recent_form: {
                  last_10: '0-0',
                  last_5: '0-0',
                  home_record: '0-0',
                  away_record: '0-0',
                  vs_conference: '0-0'
                },
                betting_stats: {
                  ats_record: '0-0',
                  ats_percentage: 0,
                  over_under: '0-0',
                  ou_percentage: 0,
                  avg_total: 0
                },
                strength_rating: 0
              };
            }
          })
        );
        
        setTeams(teamsWithStats);
      } catch (error) {
        console.error('Error fetching teams:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchTeams();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Run only once on mount

  // Preselect team when requested and teams are loaded
  useEffect(() => {
    if (!loading && preselectTeamAbbrev) {
      const t = teams.find(t => t.abbreviation.toUpperCase() === preselectTeamAbbrev.toUpperCase());
      if (t) {
        setSelectedTeam(t);
      }
    }
  }, [loading, preselectTeamAbbrev, teams]);

  // Filter and sort teams
  const filteredAndSortedTeams = teams
    .filter(team => {
      const matchesSearch = team.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          team.abbreviation.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          team.city.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesConference = selectedConference === 'All' || team.conference === selectedConference;
      const matchesDivision = selectedDivision === 'All' || team.division === selectedDivision;
      
      return matchesSearch && matchesConference && matchesDivision;
    })
    .sort((a, b) => {
      let aValue, bValue;
      
      switch (sortBy) {
        case 'win_percentage':
          aValue = a.season_stats.win_percentage;
          bValue = b.season_stats.win_percentage;
          break;
        case 'net_rating':
          aValue = a.season_stats.net_rating;
          bValue = b.season_stats.net_rating;
          break;
        case 'points_per_game':
          aValue = a.season_stats.points_per_game;
          bValue = b.season_stats.points_per_game;
          break;
        case 'strength_rating':
          aValue = a.strength_rating;
          bValue = b.strength_rating;
          break;
        case 'ats_percentage':
          aValue = a.betting_stats.ats_percentage;
          bValue = b.betting_stats.ats_percentage;
          break;
        default:
          aValue = a.full_name;
          bValue = b.full_name;
      }
      
      if (typeof aValue === 'string') {
        return sortOrder === 'asc' ? aValue.localeCompare(bValue as string) : (bValue as string).localeCompare(aValue);
      } else {
        return sortOrder === 'asc' ? (aValue as number) - (bValue as number) : (bValue as number) - (aValue as number);
      }
    });

  const conferences = ['All', 'Eastern', 'Western'];
  const divisions = ['All', 'Atlantic', 'Central', 'Southeast', 'Northwest', 'Pacific', 'Southwest'];

  const TeamCard = ({ team }: { team: Team }) => (
    <div 
      className="glass-card p-6 hover:neon-border transition-all duration-300 cursor-pointer group"
      onClick={() => { setSelectedTeam(team); onTeamSelect?.(team); }}
    >
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-white font-bold text-lg">
            {team.abbreviation}
          </div>
          <div>
            <h3 className="text-lg font-bold text-white group-hover:text-blue-400 transition-colors">
              {team.full_name}
            </h3>
            <p className="text-sm text-gray-400">{team.conference} • {team.division}</p>
          </div>
        </div>
        <Eye className="w-5 h-5 text-gray-400 group-hover:text-blue-400 transition-colors" />
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="text-center">
          <div className="text-2xl font-bold text-white">
            {team.season_stats.wins}-{team.season_stats.losses}
          </div>
          <div className="text-xs text-gray-400">Record</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-white">
            {(team.season_stats.win_percentage * 100).toFixed(1)}%
          </div>
          <div className="text-xs text-gray-400">Win %</div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2 mb-4">
        <div className="text-center">
          <div className="text-lg font-semibold text-green-400">
            {team.season_stats.offensive_rating}
          </div>
          <div className="text-xs text-gray-400">Off Rtg</div>
        </div>
        <div className="text-center">
          <div className="text-lg font-semibold text-red-400">
            {team.season_stats.defensive_rating}
          </div>
          <div className="text-xs text-gray-400">Def Rtg</div>
        </div>
      </div>

      <div className="flex items-center justify-between mb-3">
        <span className="text-sm text-gray-400">Form (Last 10)</span>
        <span className="text-sm font-medium text-white">{team.recent_form.last_10}</span>
      </div>

      <div className="flex items-center justify-between mb-3">
        <span className="text-sm text-gray-400">ATS Record</span>
        <span className="text-sm font-medium text-white">{team.betting_stats.ats_record}</span>
      </div>

      <div className="flex items-center justify-between">
        <span className="text-sm text-gray-400">Strength</span>
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${
            team.strength_rating >= 85 ? 'bg-green-400' :
            team.strength_rating >= 75 ? 'bg-yellow-400' :
            'bg-red-400'
          }`}></div>
          <span className="text-sm font-medium text-white">{team.strength_rating}</span>
        </div>
      </div>
    </div>
  );

  const TeamRow = ({ team }: { team: Team }) => (
    <tr 
      className="border-b border-gray-700/50 hover:bg-white/5 cursor-pointer transition-colors"
      onClick={() => { setSelectedTeam(team); onTeamSelect?.(team); }}
    >
      <td className="px-6 py-4">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded flex items-center justify-center text-white font-bold text-sm">
            {team.abbreviation}
          </div>
          <div>
            <div className="font-semibold text-white">{team.full_name}</div>
            <div className="text-sm text-gray-400">{team.conference}</div>
          </div>
        </div>
      </td>
      <td className="px-6 py-4 text-white font-medium">
        {team.season_stats.wins}-{team.season_stats.losses}
      </td>
      <td className="px-6 py-4 text-white">
        {(team.season_stats.win_percentage * 100).toFixed(1)}%
      </td>
      <td className="px-6 py-4 text-green-400">
        {team.season_stats.offensive_rating}
      </td>
      <td className="px-6 py-4 text-red-400">
        {team.season_stats.defensive_rating}
      </td>
      <td className="px-6 py-4">
        <div className={`flex items-center space-x-1 ${
          team.season_stats.net_rating >= 0 ? 'text-green-400' : 'text-red-400'
        }`}>
          {team.season_stats.net_rating >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
          <span>{team.season_stats.net_rating > 0 ? '+' : ''}{team.season_stats.net_rating}</span>
        </div>
      </td>
      <td className="px-6 py-4 text-white">
        {team.recent_form.last_10}
      </td>
      <td className="px-6 py-4 text-white">
        {team.betting_stats.ats_record}
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${
            team.strength_rating >= 85 ? 'bg-green-400' :
            team.strength_rating >= 75 ? 'bg-yellow-400' :
            'bg-red-400'
          }`}></div>
          <span className="text-white">{team.strength_rating}</span>
        </div>
      </td>
    </tr>
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-400">Loading teams analysis...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">NBA Teams Analysis</h1>
          <p className="text-gray-400">Comprehensive analysis of all 30 NBA teams</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setViewMode(viewMode === 'grid' ? 'table' : 'grid')}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors"
          >
            <BarChart3 className="w-4 h-4" />
            <span>{viewMode === 'grid' ? 'Table View' : 'Grid View'}</span>
          </button>
        </div>
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="glass-card p-4 text-center">
          <Users className="w-8 h-8 text-blue-400 mx-auto mb-2" />
          <div className="text-2xl font-bold text-white">{teams.length}</div>
          <div className="text-sm text-gray-400">Total Teams</div>
        </div>
        <div className="glass-card p-4 text-center">
          <Globe className="w-8 h-8 text-green-400 mx-auto mb-2" />
          <div className="text-2xl font-bold text-white">
            {teams.filter(t => t.conference === 'Eastern').length}
          </div>
          <div className="text-sm text-gray-400">Eastern</div>
        </div>
        <div className="glass-card p-4 text-center">
          <Globe className="w-8 h-8 text-purple-400 mx-auto mb-2" />
          <div className="text-2xl font-bold text-white">
            {teams.filter(t => t.conference === 'Western').length}
          </div>
          <div className="text-sm text-gray-400">Western</div>
        </div>
        <div className="glass-card p-4 text-center">
          <Target className="w-8 h-8 text-yellow-400 mx-auto mb-2" />
          <div className="text-2xl font-bold text-white">
            {filteredAndSortedTeams.length}
          </div>
          <div className="text-sm text-gray-400">Filtered</div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="glass-card p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          {/* Search */}
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <input
              type="text"
              placeholder="Search teams..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:border-blue-400 focus:outline-none"
            />
          </div>

          {/* Filters */}
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <Filter className="w-4 h-4 text-gray-400" />
              <select
                value={selectedConference}
                onChange={(e) => setSelectedConference(e.target.value)}
                className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none"
              >
                {conferences.map(conf => (
                  <option key={conf} value={conf}>{conf} Conference</option>
                ))}
              </select>
            </div>

            <select
              value={selectedDivision}
              onChange={(e) => setSelectedDivision(e.target.value)}
              className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none"
            >
              {divisions.map(div => (
                <option key={div} value={div}>{div} {div !== 'All' ? 'Division' : ''}</option>
              ))}
            </select>

            <div className="flex items-center space-x-2">
              <ArrowUpDown className="w-4 h-4 text-gray-400" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none"
              >
                <option value="win_percentage">Win %</option>
                <option value="net_rating">Net Rating</option>
                <option value="points_per_game">Points/Game</option>
                <option value="strength_rating">Strength</option>
                <option value="ats_percentage">ATS %</option>
              </select>
              <button
                onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
                className="p-2 bg-gray-700/50 hover:bg-gray-600/50 rounded-lg transition-colors"
              >
                {sortOrder === 'asc' ? <TrendingUp className="w-4 h-4 text-gray-400" /> : <TrendingDown className="w-4 h-4 text-gray-400" />}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Teams Display */}
      {viewMode === 'grid' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredAndSortedTeams.map(team => (
            <TeamCard key={team.id} team={team} />
          ))}
        </div>
      ) : (
        <div className="glass-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-800/50">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Team</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Record</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Win %</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Off Rtg</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Def Rtg</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Net Rtg</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">L10</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">ATS</th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Strength</th>
                </tr>
              </thead>
              <tbody>
                {filteredAndSortedTeams.map(team => (
                  <TeamRow key={team.id} team={team} />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {filteredAndSortedTeams.length === 0 && (
        <div className="glass-card p-12 text-center">
          <Zap className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">No teams found</h3>
          <p className="text-gray-400">Try adjusting your search or filter criteria</p>
        </div>
      )}

      {/* Team Details Panel */}
      {selectedTeam && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/50" onClick={() => setSelectedTeam(null)}></div>
          <div className="relative w-full max-w-xl h-full bg-gray-900 border-l border-gray-700/50 overflow-auto">
            <div className="p-6 border-b border-gray-700/50 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded flex items-center justify-center text-white font-bold">
                  {selectedTeam.abbreviation}
                </div>
                <div>
                  <div className="text-xl font-bold text-white">{selectedTeam.full_name}</div>
                  <div className="text-sm text-gray-400">{selectedTeam.conference} • {selectedTeam.division}</div>
                </div>
              </div>
              <button className="px-3 py-1 glass-card hover:bg-white/10 rounded text-sm" onClick={() => setSelectedTeam(null)}>Close</button>
            </div>
            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="glass-card p-4 text-center">
                  <div className="text-2xl font-bold text-white">{selectedTeam.season_stats.wins}-{selectedTeam.season_stats.losses}</div>
                  <div className="text-sm text-gray-400">Record</div>
                </div>
                <div className="glass-card p-4 text-center">
                  <div className="text-2xl font-bold text-white">{(selectedTeam.season_stats.win_percentage * 100).toFixed(1)}%</div>
                  <div className="text-sm text-gray-400">Win %</div>
                </div>
                <div className="glass-card p-4 text-center">
                  <div className="text-xl font-semibold text-green-400">{selectedTeam.season_stats.offensive_rating}</div>
                  <div className="text-sm text-gray-400">Off Rtg</div>
                </div>
                <div className="glass-card p-4 text-center">
                  <div className="text-xl font-semibold text-red-400">{selectedTeam.season_stats.defensive_rating}</div>
                  <div className="text-sm text-gray-400">Def Rtg</div>
                </div>
              </div>

              <div className="glass-card p-4">
                <div className="text-sm text-gray-400 mb-2">Key Players</div>
                <div className="flex flex-wrap gap-2">
                  {selectedTeam.key_players.map((p, idx) => (
                    <span key={idx} className="px-2 py-1 text-xs bg-gray-800/50 rounded text-white">{p}</span>
                  ))}
                </div>
              </div>

              <div className="glass-card p-4">
                <div className="text-sm text-gray-400 mb-2">Betting Stats</div>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <div className="text-gray-400">ATS</div>
                    <div className="text-white font-medium">{selectedTeam.betting_stats.ats_record} ({(selectedTeam.betting_stats.ats_percentage * 100).toFixed(1)}%)</div>
                  </div>
                  <div>
                    <div className="text-gray-400">Over/Under</div>
                    <div className="text-white font-medium">{selectedTeam.betting_stats.over_under} ({(selectedTeam.betting_stats.ou_percentage * 100).toFixed(1)}%)</div>
                  </div>
                  <div>
                    <div className="text-gray-400">Avg Total</div>
                    <div className="text-white font-medium">{selectedTeam.betting_stats.avg_total}</div>
                  </div>
                  <div>
                    <div className="text-gray-400">Strength</div>
                    <div className="text-white font-medium">{selectedTeam.strength_rating}</div>
                  </div>
                </div>
              </div>

              <div className="text-right">
                <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded text-white" onClick={() => setSelectedTeam(null)}>Done</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AllTeams;