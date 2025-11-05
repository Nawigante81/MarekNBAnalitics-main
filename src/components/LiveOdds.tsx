/* eslint-disable @typescript-eslint/no-explicit-any, react-hooks/exhaustive-deps */
import React, { useState, useEffect } from 'react';
import { TrendingUp, TrendingDown, RefreshCw, AlertTriangle, Clock, Activity } from 'lucide-react';
import { api } from '../services/api';

interface OddsData {
  gameId: string;
  homeTeam: string;
  awayTeam: string;
  startTime: string;
  bookmakers: {
    name: string;
    moneyline: { home: number; away: number };
    spread: { line: number; home: number; away: number };
    total: { line: number; over: number; under: number };
  }[];
  movements: {
    type: 'spread' | 'total' | 'ml';
    direction: 'up' | 'down';
    from: number;
    to: number;
    time: string;
  }[];
}

interface LiveAlert {
  id: string;
  type: 'movement' | 'value' | 'reverse';
  game: string;
  message: string;
  severity: 'high' | 'medium' | 'low';
  time: string;
}

interface LiveOddsProps {
  selectedGameId?: string;
}

const LiveOdds: React.FC<LiveOddsProps> = ({ selectedGameId }) => {
  const [oddsData, setOddsData] = useState<OddsData[]>([]);
  const [alerts, setAlerts] = useState<LiveAlert[]>([]);
  const [selectedGame, setSelectedGame] = useState<string | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [showSelectedOnly, setShowSelectedOnly] = useState(false);
  // Finder state
  const [homeAbbr, setHomeAbbr] = useState('');
  const [awayAbbr, setAwayAbbr] = useState('');
  const [date, setDate] = useState<string>('');
  const [slug, setSlug] = useState<string>('');
  const [foundGame, setFoundGame] = useState<OddsData | null>(null);

  const loadOdds = async () => {
    setLoading(true);
    
    try {
      // Get real live odds data from API
      const response = await api.games.getLiveOdds();
      
      if (response.games && response.games.length > 0) {
        setOddsData(response.games);
        
        // Generate alerts based on real data
        const generatedAlerts: LiveAlert[] = [];
        response.games.forEach((game: any, index: number) => {
          if (game.homeTeam.includes('Bulls') || game.awayTeam.includes('Bulls')) {
            generatedAlerts.push({
              id: `bulls-${index}`,
              type: 'movement',
              game: `${game.homeTeam} vs ${game.awayTeam}`,
              message: 'Bulls game detected - monitoring for value opportunities',
              severity: 'medium',
              time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            });
          }
          
          // Check for potential value bets (simple logic)
          if (game.bookmakers && game.bookmakers.length > 1) {
            const spreads = game.bookmakers.map((b: any) => b.spread?.home || 0);
            const maxSpread = Math.max(...spreads);
            const minSpread = Math.min(...spreads);
            
            if (maxSpread - minSpread > 0.5) {
              generatedAlerts.push({
                id: `value-${index}`,
                type: 'value',
                game: `${game.homeTeam} vs ${game.awayTeam}`,
                message: `Spread discrepancy detected: ${minSpread} to ${maxSpread}`,
                severity: 'high',
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
              });
            }
          }
        });
        
        setAlerts(generatedAlerts.slice(0, 5)); // Limit to 5 alerts
        
      } else {
        // Fallback to empty state
        setOddsData([]);
        setAlerts([{
          id: 'no-games',
          type: 'movement',
          game: 'No Games',
          message: 'No games scheduled for today',
          severity: 'low',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }]);
      }
    } catch (error) {
      console.error('Error loading odds:', error);
      setOddsData([]);
      setAlerts([{
        id: 'error',
        type: 'movement',
        game: 'API Error',
        message: 'Failed to load live odds data',
        severity: 'high',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }]);
    }

    setLoading(false);
    if (selectedGameId) {
      setSelectedGame(selectedGameId);
    }
  };

  useEffect(() => {
    loadOdds();

    if (autoRefresh) {
      const interval = setInterval(() => {
        loadOdds();
        setLastUpdate(new Date());
      }, 30000); // Refresh every 30 seconds

      return () => clearInterval(interval);
    }
  }, [autoRefresh]);

  useEffect(() => {
    if (!loading && selectedGameId) {
      setSelectedGame(selectedGameId);
    }
  }, [selectedGameId, loading]);

  const formatOdds = (odds: number) => {
    return odds > 0 ? `+${odds}` : `${odds}`;
  };

  const getBestOdds = (bookmakers: any[], market: string, side: string) => {
    let best = null;
    let bestValue = market === 'moneyline' ? (side === 'favorite' ? -1000 : -1000) : -1000;
    
    bookmakers.forEach(book => {
      let value;
      if (market === 'moneyline') {
        value = side === 'home' ? book.moneyline.home : book.moneyline.away;
      } else if (market === 'spread') {
        value = side === 'home' ? book.spread.home : book.spread.away;
      } else if (market === 'total') {
        value = side === 'over' ? book.total.over : book.total.under;
      }
      
      if (value && value > bestValue) {
        bestValue = value;
        best = book.name;
      }
    });

    return { value: bestValue, book: best };
  };

  const getConsensus = (bookmakers: OddsData['bookmakers']) => {
    const spreadLines = bookmakers.map(b => b.spread?.line).filter((n): n is number => typeof n === 'number');
    const totalLines = bookmakers.map(b => b.total?.line).filter((n): n is number => typeof n === 'number');
    const mlHome = bookmakers.map(b => b.moneyline?.home).filter((n): n is number => typeof n === 'number');
    const avg = (arr: number[]) => arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : 0;
    const range = (arr: number[]) => arr.length ? [Math.min(...arr), Math.max(...arr)] as [number, number] : undefined;
    return {
      spreadAvg: avg(spreadLines),
      spreadRange: range(spreadLines),
      totalAvg: avg(totalLines),
      totalRange: range(totalLines),
      mlHomeAvg: avg(mlHome)
    };
  };

  const mapFoundResponseToOddsData = (resp: { game: any; odds: any[] }) => {
    if (!resp || !resp.game) return null;
    const g = resp.game;
    const bookmakers = (resp.odds || []).map((b: any) => ({
      name: b.name || b.bookmaker || 'Book',
      moneyline: {
        home: b.moneyline?.home ?? b.ml?.home ?? 0,
        away: b.moneyline?.away ?? b.ml?.away ?? 0,
      },
      spread: {
        line: b.spread?.line ?? 0,
        home: b.spread?.home ?? 0,
        away: b.spread?.away ?? 0,
      },
      total: {
        line: b.total?.line ?? 0,
        over: b.total?.over ?? 0,
        under: b.total?.under ?? 0,
      },
    }));
    const mapped: OddsData = {
      gameId: g.gameId || g.id || `${g.homeTeam}-${g.awayTeam}`,
      homeTeam: g.homeTeam || g.home || g.home_abbr || 'HOME',
      awayTeam: g.awayTeam || g.away || g.away_abbr || 'AWAY',
      startTime: g.startTime || g.commence_time || g.date || '',
      bookmakers,
      movements: [],
    };
    return mapped;
  };

  const getAlertColor = (severity: string) => {
    switch (severity) {
      case 'high': return 'border-red-400/30 bg-red-600/10 text-red-400';
      case 'medium': return 'border-yellow-400/30 bg-yellow-600/10 text-yellow-400';
      case 'low': return 'border-blue-400/30 bg-blue-600/10 text-blue-400';
      default: return 'border-gray-400/30 bg-gray-600/10 text-gray-400';
    }
  };

  const getMovementIcon = (direction: string) => {
    return direction === 'up' ? 
      <TrendingUp className="w-4 h-4 text-green-400" /> : 
      <TrendingDown className="w-4 h-4 text-red-400" />;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-400">Loading live odds...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header Controls */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-white flex items-center space-x-2">
          <Activity className="w-6 h-6 text-blue-400" />
          <span>Live Odds Monitor</span>
        </h2>
        <div className="flex items-center space-x-4">
          {/* Quick Odds Finder */}
          <form
            className="hidden md:flex items-end space-x-2"
            onSubmit={async (e) => {
              e.preventDefault();
              try {
                const params: Record<string, string> = {} as any;
                if (homeAbbr) params.homeAbbr = homeAbbr.toUpperCase();
                if (awayAbbr) params.awayAbbr = awayAbbr.toUpperCase();
                if (date) params.date = date; // YYYY-MM-DD
                if (slug) params.slug = slug;
                const resp = await api.games.findOdds(params as any);
                const mapped = mapFoundResponseToOddsData(resp as any);
                if (mapped) {
                  setFoundGame(mapped);
                  setSelectedGame(mapped.gameId);
                }
              } catch (err) {
                console.error('Find odds error:', err);
                setFoundGame(null);
              }
            }}
          >
            <div className="flex flex-col">
              <label className="text-xs text-gray-400">Home</label>
              <input
                value={homeAbbr}
                onChange={(e) => setHomeAbbr(e.target.value)}
                placeholder="CHI"
                title="Home team abbreviation"
                aria-label="Home team abbreviation"
                className="px-2 py-1 rounded bg-gray-800/50 border border-gray-700/50 text-sm"
              />
            </div>
            <div className="flex flex-col">
              <label className="text-xs text-gray-400">Away</label>
              <input
                value={awayAbbr}
                onChange={(e) => setAwayAbbr(e.target.value)}
                placeholder="LAL"
                title="Away team abbreviation"
                aria-label="Away team abbreviation"
                className="px-2 py-1 rounded bg-gray-800/50 border border-gray-700/50 text-sm"
              />
            </div>
            <div className="flex flex-col">
              <label className="text-xs text-gray-400">Date</label>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                title="Game date"
                aria-label="Game date"
                className="px-2 py-1 rounded bg-gray-800/50 border border-gray-700/50 text-sm"
              />
            </div>
            <div className="flex flex-col">
              <label className="text-xs text-gray-400">Slug</label>
              <input
                value={slug}
                onChange={(e) => setSlug(e.target.value)}
                placeholder="optional"
                title="Game slug"
                aria-label="Game slug"
                className="px-2 py-1 rounded bg-gray-800/50 border border-gray-700/50 text-sm"
              />
            </div>
            <button type="submit" className="glass-card px-3 py-1 text-sm">Find</button>
          </form>
          {selectedGame && (
            <div className="glass-card px-3 py-2 flex items-center space-x-2">
              <span className="text-sm text-gray-300">Selected game:</span>
              <span className="text-sm text-blue-400">{selectedGame}</span>
              <button
                onClick={() => { setSelectedGame(null); setShowSelectedOnly(false); }}
                className="text-xs text-gray-400 hover:text-white"
              >
                Clear
              </button>
            </div>
          )}
          <label className="flex items-center space-x-2 cursor-pointer">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className="rounded"
              aria-label="Auto-refresh"
              title="Auto-refresh"
            />
            <span className="text-sm text-gray-300">Auto-refresh</span>
          </label>
          <label className="flex items-center space-x-2 cursor-pointer">
            <input
              type="checkbox"
              checked={showSelectedOnly}
              onChange={(e) => setShowSelectedOnly(e.target.checked)}
              disabled={!selectedGame}
              className="rounded"
              aria-label="Show only selected game"
              title="Show only selected game"
            />
            <span className={`text-sm ${selectedGame ? 'text-gray-300' : 'text-gray-500'}`}>Only selected</span>
          </label>
          <button
            onClick={async () => {
              await loadOdds();
              setLastUpdate(new Date());
            }}
            className="glass-card p-2 hover:bg-white/10 transition-colors"
            aria-label="Refresh odds"
            title="Refresh odds"
          >
            <RefreshCw className="w-5 h-5 text-gray-400 hover:text-white" />
          </button>
          <div className="glass-card px-3 py-2">
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-sm text-gray-300">
                Last update: {lastUpdate.toLocaleTimeString()}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
        {/* Live Alerts */}
        <div className="xl:col-span-1">
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50">
              <h3 className="text-xl font-bold text-white flex items-center space-x-2">
                <AlertTriangle className="w-5 h-5 text-yellow-400" />
                <span>Live Alerts</span>
              </h3>
            </div>
            <div className="p-6 space-y-3">
              {foundGame && (
                <div className="p-3 rounded-lg border border-blue-400/30 bg-blue-600/10 text-blue-300">
                  <div className="text-sm font-medium mb-1">Found Game</div>
                  <div className="text-xs">
                    {foundGame.homeTeam} vs {foundGame.awayTeam}
                  </div>
                  <div className="text-xs opacity-80 mt-1">Bookmakers: {foundGame.bookmakers.length}</div>
                </div>
              )}
              {alerts.map((alert) => (
                <div key={alert.id} className={`p-3 rounded-lg border ${getAlertColor(alert.severity)}`}>
                  <div className="flex items-start justify-between mb-2">
                    <div className="text-sm font-medium">{alert.game}</div>
                    <div className="text-xs opacity-70">{alert.time}</div>
                  </div>
                  <div className="text-sm opacity-90">{alert.message}</div>
                  <div className="flex items-center justify-between mt-2">
                    <span className={`text-xs px-2 py-1 rounded ${
                      alert.type === 'movement' ? 'bg-blue-600/20 text-blue-400' :
                      alert.type === 'value' ? 'bg-green-600/20 text-green-400' :
                      'bg-red-600/20 text-red-400'
                    }`}>
                      {alert.type}
                    </span>
                    <span className="text-xs opacity-60 capitalize">{alert.severity}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Odds Comparison */}
        <div className="xl:col-span-3">
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50">
              <h3 className="text-xl font-bold text-white flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <TrendingUp className="w-5 h-5 text-green-400" />
                  <span>Odds Comparison</span>
                </div>
                <span className="text-sm text-gray-400">{oddsData.length} games</span>
              </h3>
            </div>
            <div className="p-6 space-y-6">
              {(showSelectedOnly && selectedGame ? oddsData.filter(g => g.gameId === selectedGame) : oddsData).map((game) => (
                <div 
                  key={game.gameId} 
                  className={`glass-card p-4 cursor-pointer transition-all duration-300 ${
                    selectedGame === game.gameId ? 'neon-border' : 'hover:bg-white/5'
                  }`}
                  onClick={() => setSelectedGame(selectedGame === game.gameId ? null : game.gameId)}
                >
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <div className="text-lg font-semibold text-white">
                        {game.homeTeam} vs {game.awayTeam}
                      </div>
                      <div className="flex items-center space-x-4 text-sm text-gray-400">
                        <div className="flex items-center space-x-1">
                          <Clock className="w-4 h-4" />
                          <span>{game.startTime}</span>
                        </div>
                        {game.movements.length > 0 && (
                          <div className="flex items-center space-x-1">
                            <Activity className="w-4 h-4 text-yellow-400" />
                            <span>{game.movements.length} movements</span>
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      {game.homeTeam.includes('Bulls') && (
                        <span className="px-2 py-1 bg-red-600/20 text-red-400 text-xs rounded">
                          BULLS FOCUS
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Quick Best Odds */}
                  <div className="grid grid-cols-3 gap-4 mb-4">
                    <div className="text-center p-3 bg-gray-800/30 rounded-lg">
                      <div className="text-xs text-gray-400 mb-1">Spread</div>
                      <div className="text-white font-semibold">
                        {game.bookmakers[0]?.spread.line > 0 ? '+' : ''}{game.bookmakers[0]?.spread.line}
                      </div>
                      <div className="text-xs text-green-400">
                        Best: {formatOdds(getBestOdds(game.bookmakers, 'spread', 'home').value)}
                      </div>
                      {(() => { const c = getConsensus(game.bookmakers); return (
                        <div className="text-xs text-blue-300 mt-1">
                          Consensus: {c.spreadAvg ? (c.spreadAvg > 0 ? '+' : '') + c.spreadAvg.toFixed(1) : '—'}
                          {c.spreadRange && (
                            <span className="text-[10px] text-gray-400 ml-1">({c.spreadRange[0]}–{c.spreadRange[1]})</span>
                          )}
                        </div>
                      ); })()}
                    </div>
                    <div className="text-center p-3 bg-gray-800/30 rounded-lg">
                      <div className="text-xs text-gray-400 mb-1">Total</div>
                      <div className="text-white font-semibold">{game.bookmakers[0]?.total.line}</div>
                      <div className="text-xs text-green-400">
                        O: {formatOdds(getBestOdds(game.bookmakers, 'total', 'over').value)}
                      </div>
                      {(() => { const c = getConsensus(game.bookmakers); return (
                        <div className="text-xs text-purple-300 mt-1">
                          Consensus: {c.totalAvg ? c.totalAvg.toFixed(1) : '—'}
                          {c.totalRange && (
                            <span className="text-[10px] text-gray-400 ml-1">({c.totalRange[0]}–{c.totalRange[1]})</span>
                          )}
                        </div>
                      ); })()}
                    </div>
                    <div className="text-center p-3 bg-gray-800/30 rounded-lg">
                      <div className="text-xs text-gray-400 mb-1">Moneyline</div>
                      <div className="text-white font-semibold">
                        {formatOdds(game.bookmakers[0]?.moneyline.home)}
                      </div>
                      <div className="text-xs text-green-400">
                        Best: {formatOdds(getBestOdds(game.bookmakers, 'moneyline', 'home').value)}
                      </div>
                      {(() => { const c = getConsensus(game.bookmakers); return (
                        <div className="text-xs text-gray-300 mt-1">
                          Consensus: {formatOdds(Math.round(c.mlHomeAvg))}
                        </div>
                      ); })()}
                    </div>
                  </div>

                  {/* Recent Movements */}
                  {game.movements.length > 0 && (
                    <div className="border-t border-gray-700/50 pt-3">
                      <div className="text-sm font-medium text-gray-300 mb-2">Recent Movements</div>
                      <div className="flex space-x-4">
                        {game.movements.slice(0, 3).map((movement, index) => (
                          <div key={index} className="flex items-center space-x-2 text-sm">
                            {getMovementIcon(movement.direction)}
                            <span className="text-gray-400">
                              {movement.type}: {movement.from} → {movement.to}
                            </span>
                            <span className="text-xs text-gray-500">({movement.time})</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Detailed Bookmaker Comparison (when selected) */}
                  {selectedGame === game.gameId && (
                    <div className="border-t border-gray-700/50 pt-4 mt-4">
                      <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                          <thead>
                            <tr className="border-b border-gray-700/50">
                              <th className="text-left py-2 text-gray-400">Sportsbook</th>
                              <th className="text-center py-2 text-gray-400">Spread</th>
                              <th className="text-center py-2 text-gray-400">Total</th>
                              <th className="text-center py-2 text-gray-400">Moneyline</th>
                            </tr>
                          </thead>
                          <tbody>
                            {game.bookmakers.map((book, index) => (
                              <tr key={index} className="border-b border-gray-800/50">
                                <td className="py-2 font-medium text-white">{book.name}</td>
                                <td className="text-center py-2">
                                  <div className="text-white">
                                    {book.spread.line > 0 ? '+' : ''}{book.spread.line}
                                  </div>
                                  <div className="text-xs text-gray-400">
                                    {formatOdds(book.spread.home)} / {formatOdds(book.spread.away)}
                                  </div>
                                </td>
                                <td className="text-center py-2">
                                  <div className="text-white">{book.total.line}</div>
                                  <div className="text-xs text-gray-400">
                                    {formatOdds(book.total.over)} / {formatOdds(book.total.under)}
                                  </div>
                                </td>
                                <td className="text-center py-2">
                                  <div className="text-xs text-gray-400">
                                    {formatOdds(book.moneyline.home)} / {formatOdds(book.moneyline.away)}
                                  </div>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LiveOdds;