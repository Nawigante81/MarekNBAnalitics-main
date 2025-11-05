import React, { useEffect, useState } from 'react';
import { TrendingUp } from 'lucide-react';
import { api } from '../services/api';

interface Team { abbreviation: string; full_name?: string }
interface RecentGame { date: string; opponent: string; home: boolean; team_score: number; opponent_score: number; result: string }
interface TeamAnalysis {
  season_record?: { wins: number; losses: number; win_percentage: number };
  season_stats?: { offensive_rating?: number; defensive_rating?: number; net_rating?: number; wins?: number; losses?: number };
  advanced_stats?: { offensive_rating?: number; defensive_rating?: number; net_rating?: number };
  recent_games?: RecentGame[];
}

const Trend: React.FC = () => {
  const [teams, setTeams] = useState<Team[]>([]);
  const [team, setTeam] = useState<string>('CHI');
  const [loading, setLoading] = useState<boolean>(true);
  const [analysis, setAnalysis] = useState<TeamAnalysis | null>(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const tr = await api.teams.getAll();
        const list = (tr.teams || []) as Team[];
        setTeams(list);
        setTeam(list[0]?.abbreviation || 'CHI');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  useEffect(() => {
    const fetch = async () => {
      if (!team) return;
      setLoading(true);
      try {
        const r = await api.teams.getAnalysis(team);
        setAnalysis(r);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [team]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <TrendingUp className="w-8 h-8 text-blue-400" />
            <span>Trendy drużyny</span>
          </h1>
          <p className="text-gray-400">Ostatnie mecze, forma i podstawowe wskaźniki</p>
        </div>
      </div>

      <div className="glass-card p-4 flex items-center space-x-4">
        <label className="text-sm text-gray-400" htmlFor="team-trend">Drużyna</label>
        <select id="team-trend" value={team} onChange={e => setTeam(e.target.value)}
          className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none">
          {teams.map(t => (
            <option key={t.abbreviation} value={t.abbreviation}>{t.abbreviation} {t.full_name ? `- ${t.full_name}` : ''}</option>
          ))}
        </select>
      </div>

      {loading && (
        <div className="flex items-center justify-center h-40">
          <div className="w-10 h-10 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
        </div>
      )}

      {analysis && (
        <div className="space-y-4">
          <div className="glass-card p-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-sm text-gray-400">L10</div>
              <div className="text-2xl font-bold text-white">{analysis.season_record?.wins ?? analysis.season_stats?.wins ?? '-'}-{analysis.season_record?.losses ?? analysis.season_stats?.losses ?? '-'}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Off Rtg</div>
              <div className="text-xl font-semibold text-green-400">{analysis.advanced_stats?.offensive_rating ?? analysis.season_stats?.offensive_rating ?? '-'}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Def Rtg</div>
              <div className="text-xl font-semibold text-red-400">{analysis.advanced_stats?.defensive_rating ?? analysis.season_stats?.defensive_rating ?? '-'}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Net</div>
              <div className="text-xl font-semibold text-white">{analysis.advanced_stats?.net_rating ?? analysis.season_stats?.net_rating ?? '-'}</div>
            </div>
          </div>

          <div className="glass-card p-0 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800/50">
                  <tr>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Data</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Przeciwnik</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Mecz</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Wynik</th>
                  </tr>
                </thead>
                <tbody>
                  {(analysis.recent_games || []).map((g: RecentGame, idx: number) => (
                    <tr key={idx} className="border-b border-gray-700/50">
                      <td className="px-6 py-3 text-white">{g.date}</td>
                      <td className="px-6 py-3 text-white">{g.opponent}</td>
                      <td className="px-6 py-3 text-white">{g.home ? 'Home' : 'Away'}</td>
                      <td className="px-6 py-3 text-white">{g.team_score}-{g.opponent_score} ({g.result})</td>
                    </tr>
                  ))}
                  {(!analysis.recent_games || analysis.recent_games.length === 0) && (
                    <tr><td colSpan={4} className="px-6 py-6 text-center text-gray-400">Brak danych</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Trend;
