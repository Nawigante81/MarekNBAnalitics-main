import React, { useState, useEffect } from 'react';
import { Clock, Home, Activity, Target, Calendar } from 'lucide-react';
import { useApi, api } from '../services/api';

interface GameInfo {
  opponent: string;
  date: string;
  time: string;
  location: 'home' | 'away';
  venue: string;
  spread?: number;
  total?: number;
  isTonight: boolean;
}

interface LastGameResult {
  opponent: string;
  result: 'W' | 'L';
  score: string;
  date: string;
}

const Footer: React.FC = () => {
  const [nextBullsGame, setNextBullsGame] = useState<GameInfo | null>(null);
  const [lakersTonight, setLakersTonight] = useState<GameInfo | null>(null);
  const [lastBullsGame, setLastBullsGame] = useState<LastGameResult | null>(null);
  const [bullsStatus, setBullsStatus] = useState<'active' | 'injury' | 'rest'>('active');
  const [loading, setLoading] = useState(true);
  
  const apiHook = useApi();
  
  useEffect(() => {
    const fetchFooterData = async () => {
      setLoading(true);
      
      try {
        // Fetch today's games to check for Bulls and Lakers
        const todayGames = await apiHook.getTodayGames();
        
        // Check for Bulls and Lakers games tonight using today's schedule
        const bullsGameTonight = todayGames.find((game: any) => 
          (game.home_team || '').includes('Bulls') || (game.away_team || '').includes('Bulls')
        );
        const lakersGameTonight = todayGames.find((game: any) => 
          (game.home_team || '').includes('Lakers') || (game.away_team || '').includes('Lakers')
        );

        // Next Bulls game (real): if tonight, use today's game; else ask backend for the next game
        if (bullsGameTonight) {
          const isHome = (bullsGameTonight.home_team || '').includes('Bulls');
          const when = bullsGameTonight.commence_time ? new Date(bullsGameTonight.commence_time) : null;
          setNextBullsGame({
            opponent: isHome ? bullsGameTonight.away_team : bullsGameTonight.home_team,
            date: 'Tonight',
            time: when ? when.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-',
            location: isHome ? 'home' : 'away',
            venue: isHome ? 'Home' : 'Away',
            isTonight: true
          });
        } else {
          const next = await api.teams.getNextGame('CHI');
          if ((next as any).next_game === null || !next.commence_time) {
            setNextBullsGame(null);
          } else {
            const when = new Date(next.commence_time as string);
            const todayStr = new Date().toDateString();
            const isTonight = when.toDateString() === todayStr;
            setNextBullsGame({
              opponent: next.opponent || '-',
              date: isTonight ? 'Tonight' : when.toLocaleDateString([], { month: 'short', day: 'numeric' }),
              time: when.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
              location: next.home ? 'home' : 'away',
              venue: next.home ? 'Home' : 'Away',
              isTonight
            });
          }
        }

        // Lakers tonight (real) — show only if they play today
        if (lakersGameTonight) {
          const isHome = (lakersGameTonight.home_team || '').includes('Lakers');
          const when = lakersGameTonight.commence_time ? new Date(lakersGameTonight.commence_time) : null;
          setLakersTonight({
            opponent: isHome ? lakersGameTonight.away_team : lakersGameTonight.home_team,
            date: 'Tonight',
            time: when ? when.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-',
            location: isHome ? 'home' : 'away',
            venue: isHome ? 'Home' : 'Away',
            isTonight: true
          });
        } else {
          setLakersTonight(null);
        }

        // Last Bulls game (real)
        const last = await api.teams.getLastGame('CHI');
        if (!(last as any).last_game && last.date) {
          setLastBullsGame({
            opponent: last.opponent || '-',
            result: (last.result as 'W' | 'L') || 'W',
            score: `${last.team_score ?? 0}-${last.opp_score ?? 0}`,
            date: new Date(last.date as string).toLocaleDateString([], { month: 'short', day: 'numeric' })
          });
        }
        
        // Mock Bulls status - would come from injury report API
        setBullsStatus('active');
        
      } catch (error) {
        console.error('Error fetching footer data:', error);
        
        // Fallbacks: clear or minimal when failing
        setNextBullsGame(null);
        setLakersTonight(null);
        setLastBullsGame(null);
      }
      
      setLoading(false);
    };
    
    fetchFooterData();
    
    // Refresh every 5 minutes
    const interval = setInterval(fetchFooterData, 5 * 60 * 1000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400 bg-green-600/10 border-green-600/30';
      case 'injury': return 'text-red-400 bg-red-600/10 border-red-600/30';
      case 'rest': return 'text-yellow-400 bg-yellow-600/10 border-yellow-600/30';
      default: return 'text-gray-400 bg-gray-600/10 border-gray-600/30';
    }
  };
  
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <Activity className="w-4 h-4" />;
      case 'injury': return <Target className="w-4 h-4" />;
      case 'rest': return <Clock className="w-4 h-4" />;
      default: return <Activity className="w-4 h-4" />;
    }
  };
  
  if (loading) {
    return (
      <footer className="bg-gray-900/50 backdrop-blur-sm border-t border-gray-700/50 p-4">
        <div className="flex items-center justify-center">
          <div className="w-4 h-4 border-2 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mr-2"></div>
          <span className="text-gray-400 text-sm">Loading game info...</span>
        </div>
      </footer>
    );
  }
  
  return (
    <footer className="bg-gray-900/50 backdrop-blur-sm border-t border-gray-700/50 p-4">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-7xl mx-auto">
        
        {/* Bulls Status */}
        <div className="glass-card p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-white flex items-center space-x-2">
              <span className="text-red-400">🐂</span>
              <span>Bulls Status</span>
            </h3>
            <div className={`flex items-center space-x-2 px-2 py-1 rounded border ${getStatusColor(bullsStatus)}`}>
              {getStatusIcon(bullsStatus)}
              <span className="text-xs capitalize">{bullsStatus}</span>
            </div>
          </div>
          
          {lastBullsGame && (
            <div className="text-sm text-gray-300">
              <div className="flex items-center justify-between">
                <span>Last Game:</span>
                <div className="flex items-center space-x-2">
                  <span className={`px-2 py-1 rounded text-xs ${
                    lastBullsGame.result === 'W' ? 'bg-green-600/20 text-green-400' : 'bg-red-600/20 text-red-400'
                  }`}>
                    {lastBullsGame.result}
                  </span>
                  <span>{lastBullsGame.score}</span>
                </div>
              </div>
              <div className="text-xs text-gray-400 mt-1">
                vs {lastBullsGame.opponent} • {lastBullsGame.date}
              </div>
            </div>
          )}
        </div>
        
        {/* Next Bulls Game */}
        <div className="glass-card p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-white flex items-center space-x-2">
              <Calendar className="w-4 h-4 text-blue-400" />
              <span>Next Game</span>
            </h3>
            {nextBullsGame?.isTonight && (
              <div className="flex items-center space-x-1">
                <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                <span className="text-xs text-red-400">Tonight</span>
              </div>
            )}
          </div>
          
          {nextBullsGame && (
            <div className="text-sm text-gray-300">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">vs {nextBullsGame.opponent}</span>
                <div className="flex items-center space-x-1">
                  {nextBullsGame.location === 'home' ? (
                    <Home className="w-3 h-3 text-green-400" />
                  ) : (
                    <Target className="w-3 h-3 text-yellow-400" />
                  )}
                  <span className="text-xs">{nextBullsGame.location}</span>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span>{nextBullsGame.date} • {nextBullsGame.time}</span>
                {nextBullsGame.spread && (
                  <span className="text-xs text-blue-400">
                    {nextBullsGame.spread > 0 ? '+' : ''}{nextBullsGame.spread}
                  </span>
                )}
              </div>
              <div className="text-xs text-gray-400 mt-1">
                {nextBullsGame.venue}
              </div>
            </div>
          )}
        </div>
        
        {/* Lakers Tonight */}
        <div className="glass-card p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-white flex items-center space-x-2">
              <span className="text-purple-400">🏀</span>
              <span>Lakers Tonight</span>
            </h3>
            {lakersTonight?.isTonight && (
              <div className="flex items-center space-x-1">
                <div className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></div>
                <span className="text-xs text-purple-400">Live</span>
              </div>
            )}
          </div>
          
          {lakersTonight ? (
            <div className="text-sm text-gray-300">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">vs {lakersTonight.opponent}</span>
                <div className="flex items-center space-x-1">
                  {lakersTonight.location === 'home' ? (
                    <Home className="w-3 h-3 text-green-400" />
                  ) : (
                    <Target className="w-3 h-3 text-yellow-400" />
                  )}
                  <span className="text-xs">{lakersTonight.location}</span>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span>{lakersTonight.time}</span>
                {lakersTonight.spread && (
                  <span className="text-xs text-purple-400">
                    {lakersTonight.spread > 0 ? '+' : ''}{lakersTonight.spread}
                  </span>
                )}
              </div>
              <div className="text-xs text-gray-400 mt-1">
                {lakersTonight.venue}
              </div>
            </div>
          ) : (
            <div className="text-sm text-gray-400">
              No Lakers game tonight
            </div>
          )}
        </div>
        
      </div>
      
      {/* Footer Bottom */}
      <div className="mt-4 pt-4 border-t border-gray-700/30">
        <div className="flex items-center justify-center text-xs text-gray-500">
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-1">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span>Live Data Active</span>
            </div>
            <span>•</span>
            <span>MarekNBAnalyzer v1.0</span>
            <span>•</span>
            <span>Last Update: {new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;