import React, { useEffect, useState } from 'react';
import { Target } from 'lucide-react';
import { api } from '../services/api';

interface Team { abbreviation: string; full_name?: string }
interface TeamAnalysis {
  form_analysis?: { last_10_games?: string };
  recent_form?: { last_10?: string };
  season_record?: { wins: number; losses: number };
  season_stats?: { wins?: number; losses?: number; points_per_game?: number; points_allowed?: number; net_rating?: number; offensive_rating?: number; defensive_rating?: number };
  advanced_stats?: { offensive_rating?: number; defensive_rating?: number; net_rating?: number };
}

const FormView: React.FC = () => {
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

  const l10 = analysis?.form_analysis?.last_10_games || analysis?.recent_form?.last_10 ||
    `${analysis?.season_record?.wins ?? analysis?.season_stats?.wins ?? '-'}-${analysis?.season_record?.losses ?? analysis?.season_stats?.losses ?? '-'}`;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <Target className="w-8 h-8 text-blue-400" />
            <span>Forma drużyny</span>
          </h1>
          <p className="text-gray-400">Podsumowanie ostatnich 10 meczów</p>
        </div>
      </div>

      <div className="glass-card p-4 flex items-center space-x-4">
        <label className="text-sm text-gray-400" htmlFor="team-form">Drużyna</label>
        <select id="team-form" value={team} onChange={e => setTeam(e.target.value)}
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
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="glass-card p-4 text-center">
            <div className="text-sm text-gray-400">Bilans L10</div>
            <div className="text-2xl font-bold text-white">{l10}</div>
          </div>
          <div className="glass-card p-4 text-center">
            <div className="text-sm text-gray-400">Śr. punktów</div>
            <div className="text-2xl font-bold text-white">{analysis.advanced_stats?.offensive_rating ?? analysis.season_stats?.points_per_game ?? '-'}</div>
          </div>
          <div className="glass-card p-4 text-center">
            <div className="text-sm text-gray-400">Śr. straconych</div>
            <div className="text-2xl font-bold text-white">{analysis.advanced_stats?.defensive_rating ?? analysis.season_stats?.points_allowed ?? '-'}</div>
          </div>
          <div className="glass-card p-4 text-center">
            <div className="text-sm text-gray-400">Net</div>
            <div className="text-2xl font-bold text-white">{analysis.advanced_stats?.net_rating ?? analysis.season_stats?.net_rating ?? '-'}</div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FormView;
