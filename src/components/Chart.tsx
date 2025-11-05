import React, { useEffect, useMemo, useState } from 'react';
import { Activity } from 'lucide-react';
import { api } from '../services/api';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
} from 'recharts';

interface Team { abbreviation: string; full_name?: string }
type Metric = 'margin' | 'net' | 'ppg' | 'papg';

type SeriesPoint = { date: string; value: number };
type ServerPoint = { date: string; ppg: number; papg: number; net: number; margin: number };
type CombinedRow = { date: string } & Partial<Record<string, number | string>>;

const ChartView: React.FC = () => {
  const [teams, setTeams] = useState<Team[]>([]);
  const [team1, setTeam1] = useState<string>('CHI');
  const [team2, setTeam2] = useState<string>('');
  const [metric, setMetric] = useState<Metric>('margin');
  const [games, setGames] = useState<number>(20);
  const [series1, setSeries1] = useState<SeriesPoint[]>([]);
  const [series2, setSeries2] = useState<SeriesPoint[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const loadTeams = async () => {
      setLoading(true);
      try {
        const tr = await api.teams.getAll();
        const list = (tr.teams || []) as Team[];
        setTeams(list);
        setTeam1(list[0]?.abbreviation || 'CHI');
      } finally {
        setLoading(false);
      }
    };
    loadTeams();
  }, []);

  useEffect(() => {
    const fetch = async () => {
      if (!team1) return;
      setLoading(true);
      try {
        const r1 = await api.teams.getTimeSeries(team1, metric, games);
        setSeries1((r1.series || []).map((p: ServerPoint) => ({ date: p.date, value: p[metric] })));
        if (team2) {
          const r2 = await api.teams.getTimeSeries(team2, metric, games);
          setSeries2((r2.series || []).map((p: ServerPoint) => ({ date: p.date, value: p[metric] })));
        } else {
          setSeries2([]);
        }
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [team1, team2, metric, games]);

  const data = useMemo(() => {
    // Merge series by date for comparison
    const map: Record<string, CombinedRow> = {};
    series1.forEach((p) => (map[p.date] = { date: p.date, [team1]: p.value }));
    series2.forEach((p) => {
      map[p.date] = { ...(map[p.date] || { date: p.date }), [team2]: p.value };
    });
    return Object.values(map).sort((a, b) => (a.date < b.date ? -1 : 1));
  }, [series1, series2, team1, team2]);

  // Compute Y bounds from both series
  const [minY, maxY] = useMemo(() => {
    const vals = [
      ...series1.map((p) => p.value),
      ...series2.map((p) => p.value),
      0,
    ];
    if (vals.length === 0) return [-10, 10];
    const min = Math.min(...vals);
    const max = Math.max(...vals);
    const pad = Math.max(2, Math.ceil((max - min) * 0.15));
    return [Math.floor(min - pad), Math.ceil(max + pad)];
  }, [series1, series2]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <Activity className="w-8 h-8 text-green-400" />
            <span>Trendy drużyn (ostatnie mecze)</span>
          </h1>
          <p className="text-gray-400">Wybierz metrykę i porównaj 2 drużyny na wykresie</p>
        </div>
      </div>

      <div className="glass-card p-4 grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
        <div className="flex flex-col">
          <label className="text-sm text-gray-400" htmlFor="team1-chart">Drużyna 1</label>
          <select id="team1-chart" value={team1} onChange={e => setTeam1(e.target.value)}
            className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none">
            {teams.map(t => (
              <option key={t.abbreviation} value={t.abbreviation}>{t.abbreviation} {t.full_name ? `- ${t.full_name}` : ''}</option>
            ))}
          </select>
        </div>
        <div className="flex flex-col">
          <label className="text-sm text-gray-400" htmlFor="team2-chart">Drużyna 2 (opcjonalnie)</label>
          <select id="team2-chart" value={team2} onChange={e => setTeam2(e.target.value)}
            className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none">
            <option value="">—</option>
            {teams.filter(t => t.abbreviation !== team1).map(t => (
              <option key={t.abbreviation} value={t.abbreviation}>{t.abbreviation} {t.full_name ? `- ${t.full_name}` : ''}</option>
            ))}
          </select>
        </div>
        <div className="flex flex-col">
          <label className="text-sm text-gray-400" htmlFor="metric-chart">Metryka</label>
          <select id="metric-chart" value={metric} onChange={e => setMetric(e.target.value as Metric)}
            className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none">
            <option value="margin">Margin</option>
            <option value="net">Net</option>
            <option value="ppg">PPG</option>
            <option value="papg">PAPG</option>
          </select>
        </div>
        <div className="flex flex-col">
          <label className="text-sm text-gray-400" htmlFor="games-count">Liczba meczów</label>
          <input id="games-count" type="number" min={5} max={60} value={games}
            onChange={e => setGames(Math.max(5, Math.min(60, Number(e.target.value) || 20)))}
            className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none" />
        </div>
      </div>

      {loading && (
        <div className="flex items-center justify-center h-64">
          <div className="w-10 h-10 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
        </div>
      )}

      {!loading && (
        <div className="glass-card p-4">
          {data.length > 0 ? (
            <div className="w-full h-80">
              <ResponsiveContainer>
                <LineChart data={data} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis dataKey="date" tick={{ fill: '#9CA3AF', fontSize: 12 }} tickMargin={8} />
                  <YAxis domain={[minY, maxY]} tick={{ fill: '#9CA3AF', fontSize: 12 }} />
                  <Tooltip contentStyle={{ backgroundColor: 'rgba(17,24,39,0.95)', border: '1px solid #374151', color: '#E5E7EB' }} />
                  <Legend wrapperStyle={{ color: '#E5E7EB' }} />
                  <Line type="monotone" dataKey={team1} stroke="#60a5fa" strokeWidth={2} dot={false} isAnimationActive={false} />
                  {team2 && <Line type="monotone" dataKey={team2} stroke="#34d399" strokeWidth={2} dot={false} isAnimationActive={false} />}
                </LineChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="text-center text-gray-400">Brak danych do wyświetlenia</div>
          )}
        </div>
      )}
    </div>
  );
};

export default ChartView;
