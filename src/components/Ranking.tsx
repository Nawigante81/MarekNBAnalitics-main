import React, { useEffect, useMemo, useState } from 'react';
import { BarChart3 } from 'lucide-react';
import { api } from '../services/api';

interface TeamRow {
  abbreviation: string;
  full_name?: string;
  conference?: string;
  season_stats?: { win_percentage: number; net_rating?: number; points_per_game?: number };
}

type SortKey = 'win_percentage' | 'net_rating' | 'points_per_game';

const Ranking: React.FC = () => {
  const [teams, setTeams] = useState<TeamRow[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [sortBy, setSortBy] = useState<SortKey>('win_percentage');
  const [order, setOrder] = useState<'asc'|'desc'>('desc');

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const r = await api.teams.getAllAnalysis();
        setTeams((r.teams || []) as TeamRow[]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const sorted = useMemo(() => {
    const data = [...teams];
    data.sort((a,b) => {
      const av = a.season_stats?.[sortBy] ?? 0;
      const bv = b.season_stats?.[sortBy] ?? 0;
      return order === 'asc' ? (av - bv) : (bv - av);
    });
    return data;
  }, [teams, sortBy, order]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <BarChart3 className="w-8 h-8 text-blue-400" />
            <span>Ranking drużyn</span>
          </h1>
          <p className="text-gray-400">Sortuj według Win%, Net Rating lub PPG</p>
        </div>
        <div className="glass-card p-2 flex items-center space-x-2">
          <select value={sortBy} onChange={e=>setSortBy(e.target.value as SortKey)}
            aria-label="Sortuj według"
            title="Sortuj według"
            className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm">
            <option value="win_percentage">Win %</option>
            <option value="net_rating">Net Rating</option>
            <option value="points_per_game">PPG</option>
          </select>
          <button onClick={()=>setOrder(order==='asc'?'desc':'asc')} className="px-3 py-2 bg-gray-700 hover:bg-gray-600 rounded text-white text-sm">{order.toUpperCase()}</button>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-10 h-10 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
        </div>
      ) : (
        <div className="glass-card p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-800/50">
                <tr>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">#</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Drużyna</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Konferencja</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Win %</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Net</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">PPG</th>
                </tr>
              </thead>
              <tbody>
                {sorted.map((t, idx) => (
                  <tr key={t.abbreviation} className="border-b border-gray-700/50">
                    <td className="px-6 py-3 text-white">{idx+1}</td>
                    <td className="px-6 py-3 text-white">{t.full_name || t.abbreviation}</td>
                    <td className="px-6 py-3 text-white">{t.conference || '-'}</td>
                    <td className="px-6 py-3 text-white">{((t.season_stats?.win_percentage ?? 0)*100).toFixed(1)}%</td>
                    <td className="px-6 py-3 text-white">{t.season_stats?.net_rating ?? '-'}</td>
                    <td className="px-6 py-3 text-white">{t.season_stats?.points_per_game ?? '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default Ranking;
