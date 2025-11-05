import React, { useState } from 'react';
import { BarChart } from 'lucide-react';
import { api } from '../services/api';

interface Player { id: string; name: string; team_abbreviation?: string; position?: string }
interface PlayerStats { [key: string]: number }

const Statistic: React.FC = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Player[]>([]);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState<Player | null>(null);
  const [stats, setStats] = useState<PlayerStats | null>(null);

  const search = async () => {
    setLoading(true);
    try {
      const r = await api.players.searchByName(query);
      setResults((r.players || []) as Player[]);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async (player: Player) => {
    setSelected(player);
    setLoading(true);
    try {
  const r: { player: unknown; stats: PlayerStats; season: string } = await api.players.getStats(String(player.id));
  setStats(r.stats || null);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <BarChart className="w-8 h-8 text-blue-400" />
            <span>Statystyki zawodnika</span>
          </h1>
          <p className="text-gray-400">Wyszukaj zawodnika i zobacz jego statystyki</p>
        </div>
      </div>

      <div className="glass-card p-4 grid grid-cols-1 md:grid-cols-6 gap-4 items-end">
        <div className="md:col-span-4">
          <label className="block text-sm text-gray-400 mb-1">Zawodnik</label>
          <input value={query} onChange={e => setQuery(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" placeholder="np. DeMar DeRozan" />
        </div>
        <div className="md:col-span-2">
          <button onClick={search} disabled={loading}
            className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded">Szukaj</button>
        </div>
      </div>

      {results.length > 0 && (
        <div className="glass-card p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-800/50">
                <tr>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Zawodnik</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Drużyna</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Pozycja</th>
                  <th className="px-6 py-3 text-left text-sm text-gray-300">Akcja</th>
                </tr>
              </thead>
              <tbody>
                {results.map(p => (
                  <tr key={p.id} className="border-b border-gray-700/50">
                    <td className="px-6 py-3 text-white">{p.name}</td>
                    <td className="px-6 py-3 text-white">{p.team_abbreviation || '-'}</td>
                    <td className="px-6 py-3 text-white">{p.position || '-'}</td>
                    <td className="px-6 py-3">
                      <button onClick={() => loadStats(p)} className="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-white text-sm">Pokaż</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {selected && stats && (
        <div className="glass-card p-6">
          <div className="text-xl font-bold text-white mb-4">{selected.name} ({selected.team_abbreviation})</div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {Object.entries(stats).map(([k, v]) => (
              <div key={k} className="glass-card p-4 text-center">
                <div className="text-sm text-gray-400 mb-1">{k}</div>
                <div className="text-2xl font-bold text-white">{typeof v === 'number' ? v.toFixed(1) : String(v)}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {loading && (
        <div className="flex items-center justify-center h-40">
          <div className="w-10 h-10 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
        </div>
      )}
    </div>
  );
};

export default Statistic;
