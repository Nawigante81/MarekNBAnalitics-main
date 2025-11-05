import React, { useEffect, useMemo, useState } from 'react';
import { Activity, TrendingUp, AlertTriangle, BarChart3, Target } from 'lucide-react';
import { api, TeamStatsResponse } from '../services/api';

type TeamRow = TeamStatsResponse & {
  season_stats: NonNullable<TeamStatsResponse['season_stats']> & {
    points_per_game?: number;
    points_allowed?: number;
    net_rating?: number;
  };
  recent_form?: { last_10?: string };
};

function parseFormScore(form?: string) {
  // form like "7-3" -> score = wins - losses
  if (!form) return 0;
  const m = form.match(/(\d+)\s*-\s*(\d+)/);
  if (!m) return 0;
  const wins = parseInt(m[1] || '0', 10);
  const losses = parseInt(m[2] || '0', 10);
  return wins - losses;
}

const LeagueTrends: React.FC = () => {
  const [teams, setTeams] = useState<TeamRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const resp = await api.teams.getAllAnalysis();
        setTeams((resp.teams || []) as TeamRow[]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const topNet = useMemo(() => {
    return [...teams]
      .filter(t => t.season_stats)
      .sort((a, b) => (b.season_stats.net_rating ?? 0) - (a.season_stats.net_rating ?? 0))
      .slice(0, 5);
  }, [teams]);

  const topForm = useMemo(() => {
    return [...teams]
      .sort((a, b) => parseFormScore(b.recent_form?.last_10) - parseFormScore(a.recent_form?.last_10))
      .slice(0, 5);
  }, [teams]);

  const bestOffense = useMemo(() => {
    return [...teams]
      .filter(t => typeof t.season_stats?.points_per_game === 'number')
      .sort((a, b) => (b.season_stats.points_per_game ?? 0) - (a.season_stats.points_per_game ?? 0))
      .slice(0, 5);
  }, [teams]);

  const bestDefense = useMemo(() => {
    return [...teams]
      .filter(t => typeof t.season_stats?.points_allowed === 'number')
      .sort((a, b) => (a.season_stats.points_allowed ?? 0) - (b.season_stats.points_allowed ?? 0))
      .slice(0, 5);
  }, [teams]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <Activity className="w-8 h-8 text-green-400" />
            <span>League trends</span>
          </h1>
          <p className="text-gray-400">Ranking skuteczności, formy i profilu atak/obrona (ostatnie 10 gier).</p>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-10 h-10 border-4 border-green-400/30 border-t-green-400 rounded-full animate-spin" />
        </div>
      ) : (
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          {/* Net rating leaders */}
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50 flex items-center justify-between">
              <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                <BarChart3 className="w-5 h-5 text-blue-400" />
                <span>Top Net Rating</span>
              </h2>
            </div>
            <div className="p-6 space-y-3">
              {topNet.map((t, i) => (
                <div key={t.abbreviation} className="flex items-center justify-between p-3 bg-gray-800/30 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <span className="w-6 text-gray-400">{i + 1}</span>
                    <span className="text-white font-medium">{t.full_name || t.abbreviation}</span>
                  </div>
                  <div className="text-green-400 font-semibold">{t.season_stats?.net_rating ?? '-'}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Form leaders (last 10) */}
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50 flex items-center justify-between">
              <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                <Activity className="w-5 h-5 text-orange-400" />
                <span>Najlepsza forma (10)</span>
              </h2>
            </div>
            <div className="p-6 space-y-3">
              {topForm.map((t, i) => (
                <div key={t.abbreviation} className="flex items-center justify-between p-3 bg-gray-800/30 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <span className="w-6 text-gray-400">{i + 1}</span>
                    <span className="text-white font-medium">{t.full_name || t.abbreviation}</span>
                  </div>
                  <div className="text-blue-300 font-semibold">{t.recent_form?.last_10 || '-'}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Offense vs Defense leaders */}
          <div className="glass-card">
            <div className="p-6 border-b border-gray-700/50 flex items-center justify-between">
              <h2 className="text-xl font-bold text-white flex items-center space-x-2">
                <Target className="w-5 h-5 text-purple-400" />
                <span>Profil: Atak / Obrona</span>
              </h2>
            </div>
            <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <div className="text-sm text-gray-400 mb-2 flex items-center space-x-2">
                  <TrendingUp className="w-4 h-4 text-green-400" />
                  <span>Najlepszy atak (PPG)</span>
                </div>
                <div className="space-y-2">
                  {bestOffense.map(t => (
                    <div key={t.abbreviation} className="flex items-center justify-between p-2 bg-gray-800/30 rounded">
                      <span className="text-white">{t.full_name || t.abbreviation}</span>
                      <span className="text-green-400 font-medium">{t.season_stats?.points_per_game ?? '-'}</span>
                    </div>
                  ))}
                </div>
              </div>
              <div>
                <div className="text-sm text-gray-400 mb-2 flex items-center space-x-2">
                  <AlertTriangle className="w-4 h-4 text-red-400" />
                  <span>Najmniej traconych (PAPG)</span>
                </div>
                <div className="space-y-2">
                  {bestDefense.map(t => (
                    <div key={t.abbreviation} className="flex items-center justify-between p-2 bg-gray-800/30 rounded">
                      <span className="text-white">{t.full_name || t.abbreviation}</span>
                      <span className="text-red-400 font-medium">{t.season_stats?.points_allowed ?? '-'}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LeagueTrends;
