import React, { useState, useEffect } from 'react';
import { Clock, Home, Activity, Target, Calendar } from 'lucide-react';
import { useApi } from '../services/api';

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
        
        // Check for Bulls game tonight
        const bullsGameTonight = todayGames.find((game: Record<string, unknown>) => 
          (game.home_team as string)?.includes('Bulls') || (game.away_team as string)?.includes('Bulls')
        );
        
        // Check for Lakers game tonight
        const lakersGameTonight = todayGames.find((game: Record<string, unknown>) => 
          (game.home_team as string)?.includes('Lakers') || (game.away_team as string)?.includes('Lakers')
        );
        
        if (bullsGameTonight) {
          const isBullsHome = bullsGameTonight.home_team?.includes('Bulls');
          setNextBullsGame({
            opponent: isBullsHome ? bullsGameTonight.away_team : bullsGameTonight.home_team,
            date: 'Tonight',
            time: bullsGameTonight.commence_time ? new Date(bullsGameTonight.commence_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '8:00 PM',
            location: isBullsHome ? 'home' : 'away',
            venue: isBullsHome ? 'United Center' : 'Away',
            spread: -2.5, // Mock - would come from odds API
            total: 225.5, // Mock - would come from odds API
            isTonight: true
          });
        } else {
          // Mock next Bulls game if not tonight
          setNextBullsGame({
            opponent: 'Miami Heat',
            date: 'Nov 5',
            time: '7:30 PM',
            location: 'away',
            venue: 'FTX Arena',
            spread: 1.5,
            total: 220.0,
            isTonight: false
          });
        }
        
        if (lakersGameTonight) {
          const isLakersHome = lakersGameTonight.home_team?.includes('Lakers');
          setLakersTonight({
            opponent: isLakersHome ? lakersGameTonight.away_team : lakersGameTonight.home_team,
            date: 'Tonight',
            time: lakersGameTonight.commence_time ? new Date(lakersGameTonight.commence_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '10:30 PM',
            location: isLakersHome ? 'home' : 'away',
            venue: isLakersHome ? 'Crypto.com Arena' : 'Away',
            spread: 3.5, // Mock
            total: 228.5, // Mock
            isTonight: true
          });
        }
        
        // Mock last Bulls game result
        setLastBullsGame({
          opponent: 'Detroit Pistons',
          result: 'W',
          score: '112-108',
          date: 'Nov 1'
        });
        
        // Mock Bulls status - would come from injury report API
        setBullsStatus('active');
        
      } catch (error) {
        console.error('Error fetching footer data:', error);
        
        // Fallback mock data
        setNextBullsGame({
          opponent: 'Los Angeles Lakers',
          date: 'Tonight',
          time: '8:00 PM',
          location: 'home',
          venue: 'United Center',
          spread: -2.5,
          total: 225.5,
          isTonight: true
        });
        
        setLakersTonight({
          opponent: 'Chicago Bulls',
          date: 'Tonight', 
          time: '8:00 PM',
          location: 'away',
          venue: 'United Center',
          spread: 2.5,
          total: 225.5,
          isTonight: true
        });
        
        setLastBullsGame({
          opponent: 'Detroit Pistons',
          result: 'W', 
          score: '112-108',
          date: 'Nov 1'
        });
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