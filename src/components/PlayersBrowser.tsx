import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Search, 
  Filter, 
  X, 
  TrendingUp,
  BarChart3
} from 'lucide-react';
import { api } from '../services/api';

interface Player {
  id: string;
  name: string;
  team_abbreviation?: string;
  position?: string;
  jersey_number?: number;
  is_active?: boolean;
  teams?: {
    abbreviation: string;
    full_name: string;
  };
  // Stats (mock for now, would come from real API)
  stats?: {
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
  };
}

const PlayersBrowser: React.FC = () => {
  const [players, setPlayers] = useState<Player[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTeam, setSelectedTeam] = useState<string>('All');
  const [selectedPosition, setSelectedPosition] = useState<string>('All');
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null);
  const [comparisonPlayers, setComparisonPlayers] = useState<Player[]>([]);
  const [showComparison, setShowComparison] = useState(false);
  const [teams, setTeams] = useState<{abbreviation: string}[]>([]);

  const positions = ['All', 'PG', 'SG', 'SF', 'PF', 'C'];

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        // Fetch players
        const playersResponse = await api.players.getAll({
          active: true,
          ...(selectedTeam !== 'All' && { team: selectedTeam }),
          ...(selectedPosition !== 'All' && { position: selectedPosition })
        });
        
        // Fetch stats for each player
        const playersWithStats = await Promise.all(
          (playersResponse.players || []).map(async (player: any) => {
            try {
              const statsResponse = await api.players.getStats(player.id);
              return {
                ...player,
                stats: statsResponse.stats
              };
            } catch (error) {
              console.error(`Error fetching stats for player ${player.id}:`, error);
              // Return player without stats if API call fails
              return {
                ...player,
                stats: null
              };
            }
          })
        );
        
        setPlayers(playersWithStats);

        // Fetch teams for filter
        const teamsResponse = await api.teams.getAll();
        setTeams([{abbreviation: 'All'}, ...(teamsResponse.teams || [])]);
      } catch (error) {
        console.error('Error fetching players:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [selectedTeam, selectedPosition]);

  // Get player image URL (using NBA API format or placeholder)
  const getPlayerImage = (player: Player) => {
    // Format: https://cdn.nba.com/headshots/nba/latest/260x190/{playerId}.png
    // For now, use a placeholder or construct from name
    const playerId = player.id;
    if (playerId && playerId !== 'mock') {
      return `https://cdn.nba.com/headshots/nba/latest/260x190/${playerId}.png`;
    }
    // Fallback: use placeholder avatar service
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(player.name)}&size=200&background=random&color=fff`;
  };

  const filteredPlayers = players.filter(player => {
    const matchesSearch = player.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      player.team_abbreviation?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      player.position?.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const addToComparison = (player: Player) => {
    if (comparisonPlayers.length >= 4) {
      alert('Możesz porównać maksymalnie 4 zawodników');
      return;
    }
    if (!comparisonPlayers.find(p => p.id === player.id)) {
      setComparisonPlayers([...comparisonPlayers, player]);
    }
  };

  const removeFromComparison = (playerId: string) => {
    setComparisonPlayers(comparisonPlayers.filter(p => p.id !== playerId));
  };

  const toggleComparison = () => {
    if (showComparison && comparisonPlayers.length === 0) return;
    setShowComparison(!showComparison);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-400">Ładowanie zawodników...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <Users className="w-8 h-8 text-blue-400" />
            <span>Przeglądarka Zawodników</span>
          </h1>
          <p className="text-gray-400">Przeglądaj, porównuj i analizuj zawodników NBA</p>
        </div>
        {comparisonPlayers.length > 0 && (
          <button
            onClick={toggleComparison}
            className="flex items-center space-x-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg transition-colors"
          >
            <BarChart3 className="w-5 h-5" />
            <span>Porównaj ({comparisonPlayers.length})</span>
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="glass-card p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <input
              type="text"
              placeholder="Szukaj zawodnika..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:border-blue-400 focus:outline-none"
            />
          </div>

          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <Filter className="w-4 h-4 text-gray-400" />
              <select
                value={selectedTeam}
                onChange={(e) => setSelectedTeam(e.target.value)}
                className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none"
              >
                {teams.map(team => (
                  <option key={team.abbreviation} value={team.abbreviation}>
                    {team.abbreviation === 'All' ? 'Wszystkie drużyny' : team.abbreviation}
                  </option>
                ))}
              </select>
            </div>

            <select
              value={selectedPosition}
              onChange={(e) => setSelectedPosition(e.target.value)}
              className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none"
            >
              {positions.map(pos => (
                <option key={pos} value={pos}>{pos === 'All' ? 'Wszystkie pozycje' : pos}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Comparison View */}
      {showComparison && comparisonPlayers.length > 0 && (
        <div className="glass-card p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-white flex items-center space-x-2">
              <BarChart3 className="w-6 h-6 text-purple-400" />
              <span>Porównanie Statystyk</span>
            </h2>
            <button
              onClick={() => setComparisonPlayers([])}
              className="text-sm text-gray-400 hover:text-white"
            >
              Wyczyść wszystkie
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-700/50">
                  <th className="text-left py-3 px-4 text-gray-400">Statystyka</th>
                  {comparisonPlayers.map(player => (
                    <th key={player.id} className="text-center py-3 px-4 text-white">
                      <div className="flex flex-col items-center">
                        <img 
                          src={getPlayerImage(player)} 
                          alt={player.name}
                          className="w-16 h-16 rounded-full mb-2 object-cover"
                          onError={(e) => {
                            (e.target as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${encodeURIComponent(player.name)}&size=64&background=random&color=fff`;
                          }}
                        />
                        <div className="font-semibold">{player.name}</div>
                        <div className="text-xs text-gray-400">{player.team_abbreviation} • {player.position}</div>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {comparisonPlayers[0]?.stats && Object.entries(comparisonPlayers[0].stats).map(([stat]) => {
                  const statLabels: Record<string, string> = {
                    ppg: 'Punkty na mecz',
                    rpg: 'Zbiórki na mecz',
                    apg: 'Asysty na mecz',
                    fg_percentage: 'FG%',
                    three_point_percentage: '3P%',
                    ft_percentage: 'FT%',
                    steals: 'Przechwyty',
                    blocks: 'Bloki',
                    turnovers: 'Straty',
                    minutes_per_game: 'Minuty na mecz'
                  };

                  const values = comparisonPlayers.map(p => p.stats?.[stat as keyof typeof p.stats] || 0);
                  const maxValue = Math.max(...values);
                  const isPercentage = stat.includes('percentage');

                  return (
                    <tr key={stat} className="border-b border-gray-800/50">
                      <td className="py-3 px-4 text-gray-300 font-medium">{statLabels[stat] || stat}</td>
                      {comparisonPlayers.map((player) => {
                        const playerValue = player.stats?.[stat as keyof typeof player.stats] || 0;
                        const isMax = playerValue === maxValue && values.filter(v => v === maxValue).length === 1;
                        return (
                          <td key={player.id} className="py-3 px-4 text-center">
                            <div className={`flex items-center justify-center space-x-2 ${
                              isMax ? 'text-green-400 font-bold' : 'text-white'
                            }`}>
                              <span>
                                {isPercentage 
                                  ? `${(playerValue * 100).toFixed(1)}%`
                                  : typeof playerValue === 'number' 
                                    ? playerValue.toFixed(1)
                                    : playerValue
                                }
                              </span>
                              {isMax && <TrendingUp className="w-4 h-4" />}
                            </div>
                          </td>
                        );
                      })}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Players Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {filteredPlayers.map(player => {
          const isInComparison = comparisonPlayers.some(p => p.id === player.id);
          return (
            <div 
              key={player.id} 
              className="glass-card p-6 hover:neon-border transition-all duration-300 cursor-pointer group"
              onClick={() => setSelectedPlayer(player)}
            >
              <div className="flex flex-col items-center mb-4">
                <img 
                  src={getPlayerImage(player)} 
                  alt={player.name}
                  className="w-32 h-32 rounded-full mb-3 object-cover border-4 border-gray-700 group-hover:border-blue-500 transition-colors"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${encodeURIComponent(player.name)}&size=128&background=random&color=fff`;
                  }}
                />
                <h3 className="text-lg font-bold text-white text-center group-hover:text-blue-400 transition-colors">
                  {player.name}
                </h3>
                <div className="text-sm text-gray-400 mt-1">
                  #{player.jersey_number || '?'} • {player.position || 'N/A'} • {player.team_abbreviation || 'N/A'}
                </div>
              </div>

              {player.stats && (
                <div className="grid grid-cols-3 gap-2 text-center mb-4">
                  <div>
                    <div className="text-lg font-bold text-white">{player.stats.ppg.toFixed(1)}</div>
                    <div className="text-xs text-gray-400">PPG</div>
                  </div>
                  <div>
                    <div className="text-lg font-bold text-white">{player.stats.rpg.toFixed(1)}</div>
                    <div className="text-xs text-gray-400">RPG</div>
                  </div>
                  <div>
                    <div className="text-lg font-bold text-white">{player.stats.apg.toFixed(1)}</div>
                    <div className="text-xs text-gray-400">APG</div>
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    if (isInComparison) {
                      removeFromComparison(player.id);
                    } else {
                      addToComparison(player);
                    }
                  }}
                  className={`px-3 py-1 rounded text-sm transition-colors ${
                    isInComparison
                      ? 'bg-purple-600 hover:bg-purple-700 text-white'
                      : 'bg-gray-700 hover:bg-gray-600 text-gray-300'
                  }`}
                >
                  {isInComparison ? 'Usuń z porównania' : 'Dodaj do porównania'}
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedPlayer(player);
                  }}
                  className="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-sm text-white"
                >
                  Szczegóły
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {filteredPlayers.length === 0 && (
        <div className="glass-card p-12 text-center">
          <Users className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">Brak zawodników</h3>
          <p className="text-gray-400">Spróbuj zmienić filtry lub wyszukiwanie</p>
        </div>
      )}

      {/* Player Details Modal */}
      {selectedPlayer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/70" onClick={() => setSelectedPlayer(null)}></div>
          <div className="relative w-full max-w-4xl max-h-[90vh] bg-gray-900 border border-gray-700/50 rounded-lg overflow-auto">
            <div className="p-6 border-b border-gray-700/50 flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <img 
                  src={getPlayerImage(selectedPlayer)} 
                  alt={selectedPlayer.name}
                  className="w-20 h-20 rounded-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${encodeURIComponent(selectedPlayer.name)}&size=80&background=random&color=fff`;
                  }}
                />
                <div>
                  <h2 className="text-2xl font-bold text-white">{selectedPlayer.name}</h2>
                  <div className="text-gray-400">
                    #{selectedPlayer.jersey_number || '?'} • {selectedPlayer.position || 'N/A'} • {selectedPlayer.team_abbreviation || 'N/A'}
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSelectedPlayer(null)}
                className="p-2 hover:bg-white/10 rounded transition-colors"
              >
                <X className="w-6 h-6 text-gray-400" />
              </button>
            </div>

            <div className="p-6">
              {selectedPlayer.stats && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                  {Object.entries(selectedPlayer.stats).map(([stat, value]) => {
                    const statLabels: Record<string, string> = {
                      ppg: 'Punkty na mecz',
                      rpg: 'Zbiórki na mecz',
                      apg: 'Asysty na mecz',
                      fg_percentage: 'FG%',
                      three_point_percentage: '3P%',
                      ft_percentage: 'FT%',
                      steals: 'Przechwyty',
                      blocks: 'Bloki',
                      turnovers: 'Straty',
                      minutes_per_game: 'Minuty na mecz'
                    };

                    const isPercentage = stat.includes('percentage');
                    return (
                      <div key={stat} className="glass-card p-4 text-center">
                        <div className="text-sm text-gray-400 mb-1">{statLabels[stat] || stat}</div>
                        <div className="text-2xl font-bold text-white">
                          {isPercentage 
                            ? `${(value * 100).toFixed(1)}%`
                            : typeof value === 'number' 
                              ? value.toFixed(1)
                              : value
                          }
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              <div className="flex items-center space-x-4">
                <button
                  onClick={() => {
                    addToComparison(selectedPlayer);
                    setSelectedPlayer(null);
                  }}
                  className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-white"
                  disabled={comparisonPlayers.some(p => p.id === selectedPlayer.id) || comparisonPlayers.length >= 4}
                >
                  Dodaj do porównania
                </button>
                <button
                  onClick={() => setSelectedPlayer(null)}
                  className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded text-white"
                >
                  Zamknij
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PlayersBrowser;

