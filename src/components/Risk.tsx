import React, { useEffect, useState } from 'react';
import { AlertTriangle } from 'lucide-react';
import { api } from '../services/api';

type KellyResult = { kelly_fraction: number; percentage: number; recommended_stake: string };
type RecommendationLeg = { game: string; bet: string; odds: number; confidence: number };
type Recommendation = {
  id: string;
  title: string;
  legs?: RecommendationLeg[];
  totalOdds?: number | string;
  risk?: string;
};

const Risk: React.FC = () => {
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [prob, setProb] = useState<string>('0.55');
  const [odds, setOdds] = useState<string>('1.90');
  const [kelly, setKelly] = useState<KellyResult | null>(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const r = await api.betting.getRecommendations();
        setRecommendations((r?.recommendations || []) as Recommendation[]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const calcKelly = async () => {
    const p = parseFloat(prob);
    const o = parseFloat(odds);
    if (isNaN(p) || isNaN(o)) return;
    const r = await api.betting.calculateKelly(p, o);
    setKelly(r);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <AlertTriangle className="w-8 h-8 text-yellow-400" />
            <span>Ryzyko i zarządzanie stawką</span>
          </h1>
          <p className="text-gray-400">Proponowane typy oraz kalkulator Kelly'ego</p>
        </div>
      </div>

      <div className="glass-card p-4 grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
        <div>
          <label className="block text-sm text-gray-400 mb-1" htmlFor="prob-input">Prawdopodobieństwo (0-1)</label>
          <input id="prob-input" value={prob} onChange={e=>setProb(e.target.value)}
            placeholder="np. 0.55" title="Szacowane prawdopodobieństwo wygranej"
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" />
        </div>
        <div>
          <label className="block text-sm text-gray-400 mb-1" htmlFor="odds-input">Kurs (dziesiętny)</label>
          <input id="odds-input" value={odds} onChange={e=>setOdds(e.target.value)}
            placeholder="np. 1.90" title="Kurs dziesiętny"
            className="w-full px-3 py-2 bg-gray-700/50 border border-gray-600 rounded text-white" />
        </div>
        <div>
          <button onClick={calcKelly} className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded">Oblicz Kelly</button>
        </div>
      </div>

      {kelly && (
        <div className="glass-card p-4 grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-sm text-gray-400">Frakcja Kelly</div>
            <div className="text-2xl font-bold text-white">{kelly.kelly_fraction.toFixed(4)}</div>
          </div>
          <div>
            <div className="text-sm text-gray-400">% Bankrolla</div>
            <div className="text-2xl font-bold text-white">{kelly.percentage.toFixed(2)}%</div>
          </div>
          <div>
            <div className="text-sm text-gray-400">Rekomendacja</div>
            <div className="text-xl font-semibold text-white">{kelly.recommended_stake}</div>
          </div>
        </div>
      )}

      <div className="glass-card p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-800/50">
              <tr>
                <th className="px-6 py-3 text-left text-sm text-gray-300">Tytuł</th>
                <th className="px-6 py-3 text-left text-sm text-gray-300">Mecz</th>
                <th className="px-6 py-3 text-left text-sm text-gray-300">Kurs</th>
                <th className="px-6 py-3 text-left text-sm text-gray-300">Ryzyko</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr><td colSpan={4} className="px-6 py-6 text-center text-gray-400">Ładowanie rekomendacji…</td></tr>
              )}
              {!loading && recommendations.map((r) => (
                <tr key={r.id} className="border-b border-gray-700/50">
                  <td className="px-6 py-3 text-white">{r.title}</td>
                  <td className="px-6 py-3 text-white">{r.legs?.[0]?.game}</td>
                  <td className="px-6 py-3 text-white">{r.totalOdds}</td>
                  <td className="px-6 py-3 text-white">{r.risk}</td>
                </tr>
              ))}
              {!loading && recommendations.length === 0 && (
                <tr><td colSpan={4} className="px-6 py-6 text-center text-gray-400">Brak rekomendacji</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Risk;
