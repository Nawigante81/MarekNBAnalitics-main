import React, { useEffect, useState } from 'react';
import { Users, RefreshCw } from 'lucide-react';
import { api } from '../services/api';

interface Team { abbreviation: string; full_name?: string; }
interface Player { id: string; name: string; position?: string; jersey_number?: number; }

const Roster: React.FC = () => {
  const [teams, setTeams] = useState<Team[]>([]);
  const [selectedTeam, setSelectedTeam] = useState<string>('CHI');
  const [players, setPlayers] = useState<Player[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [updating, setUpdating] = useState<boolean>(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const tr = await api.teams.getAll();
        const list = (tr.teams || []) as Team[];
        setTeams(list);
        const initial = list.find(t => t.abbreviation === selectedTeam)?.abbreviation || list[0]?.abbreviation || 'CHI';
        setSelectedTeam(initial);
      } finally {
        setLoading(false);
      }
    };
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const fetchRoster = async () => {
      if (!selectedTeam) return;
      setUpdating(true);
      try {
        const rr = await api.teams.getPlayers(selectedTeam);
        setPlayers((rr.players || []) as Player[]);
      } finally {
        setUpdating(false);
      }
    };
    fetchRoster();
  }, [selectedTeam]);

  const triggerUpdate = async () => {
    setUpdating(true);
    try {
      await api.system.triggerRosterScrape();
      const rr = await api.teams.getPlayers(selectedTeam);
      setPlayers((rr.players || []) as Player[]);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-400">Ładowanie drużyn...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center space-x-2">
            <Users className="w-8 h-8 text-blue-400" />
            <span>Skład drużyny</span>
          </h1>
          <p className="text-gray-400">Wybierz drużynę, aby zobaczyć aktualny roster</p>
        </div>
        <button onClick={triggerUpdate} disabled={updating} className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg">
          <RefreshCw className={`w-4 h-4 ${updating ? 'animate-spin' : ''}`} />
          <span>Odśwież skład</span>
        </button>
      </div>

      <div className="glass-card p-4 flex items-center space-x-4">
        <label className="text-sm text-gray-400" htmlFor="team-select">Drużyna</label>
        <select id="team-select" value={selectedTeam} onChange={e => setSelectedTeam(e.target.value)}
          className="bg-gray-700/50 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:border-blue-400 focus:outline-none">
          {teams.map(t => (
            <option key={t.abbreviation} value={t.abbreviation}>
              {t.abbreviation} {t.full_name ? `- ${t.full_name}` : ''}
            </option>
          ))}
        </select>
      </div>

      <div className="glass-card p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-800/50">
              <tr>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">#</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Zawodnik</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-300">Pozycja</th>
              </tr>
            </thead>
            <tbody>
              {players.map(p => (
                <tr key={p.id} className="border-b border-gray-700/50">
                  <td className="px-6 py-3 text-white">{p.jersey_number ?? '-'}</td>
                  <td className="px-6 py-3 text-white">{p.name}</td>
                  <td className="px-6 py-3 text-white">{p.position ?? '-'}</td>
                </tr>
              ))}
              {players.length === 0 && (
                <tr>
                  <td colSpan={3} className="px-6 py-6 text-center text-gray-400">Brak zawodników</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Roster;
