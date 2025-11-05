import React, { useState } from 'react';
import { LineChart, Search } from 'lucide-react';
import { api } from '../services/api';

interface FlatOdd {
  bookmaker_title: string;
  bookmaker_key?: string;
  market_type: string;
  team?: string;
  outcome_name?: string;
  point?: number;
  price: number;
}
interface FindOddsResult {
  game: { homeTeam: string; awayTeam: string; startTime: string } | null;
  odds: FlatOdd[];
  source: string;
  note?: string;
}

const Line: React.FC = () => {
  const [homeAbbr, setHomeAbbr] = useState('CHI');
  const [awayAbbr, setAwayAbbr] = useState('LAL');
  const [date, setDate] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<FindOddsResult | null>(null);

  const find = async () => {
    setLoading(true);
    try {
      const r = await api.games.findOdds({ homeAbbr, awayAbbr, date: date || undefined });
      setResult(r);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <LineChart className="w-8 h-8 text-blue-400" />
            <span>Kursy (Line)</span>
          </h1>
          <p className="text-gray-400">Wyszukaj kursy dla meczu po skrótach drużyn i dacie</p>
        </div>
      </div>

      <div className="glass-card p-4 grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
        <div>
          <label className="block text-sm text-gray-400 mb-1">Gospodarz (abbr)</label>
          <input value={homeAbbr} onChange={e => setHomeAbbr(e.target.value.toUpperCase())}
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" placeholder="CHI" />
        </div>
        <div>
          <label className="block text-sm text-gray-400 mb-1">Goście (abbr)</label>
          <input value={awayAbbr} onChange={e => setAwayAbbr(e.target.value.toUpperCase())}
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" placeholder="LAL" />
        </div>
        <div>
          <label className="block text-sm text-gray-400 mb-1">Data (YYYY-MM-DD)</label>
          <input value={date} onChange={e => setDate(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" placeholder="2025-11-05" />
        </div>
        <div>
          <button onClick={find} disabled={loading}
            className="w-full flex items-center justify-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg">
            <Search className={`w-4 h-4 ${loading ? 'animate-pulse' : ''}`} />
            <span>Szukaj kursów</span>
          </button>
        </div>
      </div>

      {result && (
        <div className="space-y-4">
          <div className="glass-card p-4">
            <div className="text-gray-300 text-sm">Źródło: {result.source}</div>
            {result.game ? (
              <div className="text-white font-medium">{result.game.homeTeam} vs {result.game.awayTeam} • {result.game.startTime}</div>
            ) : (
              <div className="text-gray-400">Nie znaleziono meczu</div>
            )}
          </div>

          <div className="glass-card p-0 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800/50">
                  <tr>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Book</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Rynek</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Zespół/Outcome</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Linia</th>
                    <th className="px-6 py-3 text-left text-sm text-gray-300">Kurs</th>
                  </tr>
                </thead>
                <tbody>
                  {(result.odds || []).map((o: FlatOdd, idx: number) => (
                    <tr key={idx} className="border-b border-gray-700/50">
                      <td className="px-6 py-3 text-white">{o.bookmaker_title}</td>
                      <td className="px-6 py-3 text-white">{o.market_type}</td>
                      <td className="px-6 py-3 text-white">{o.team || o.outcome_name}</td>
                      <td className="px-6 py-3 text-white">{o.point ?? '-'}</td>
                      <td className="px-6 py-3 text-white">{o.price}</td>
                    </tr>
                  ))}
                  {(!result.odds || result.odds.length === 0) && (
                    <tr><td colSpan={5} className="px-6 py-6 text-center text-gray-400">Brak kursów</td></tr>
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

export default Line;
