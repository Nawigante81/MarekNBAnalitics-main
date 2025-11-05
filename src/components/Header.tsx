import React, { useEffect, useRef, useState } from 'react';
import { Bell, RefreshCw, Settings, Users } from 'lucide-react';
import { createPortal } from 'react-dom';
import api from '../services/api';

interface HeaderProps {
  activeSection: string;
  lastUpdate: Date;
  onRefresh: () => void;
  settings: {
    liveAnimationsEnabled: boolean;
    notificationsEnabled: boolean;
  };
  onToggleSetting: (
    key: 'liveAnimationsEnabled' | 'notificationsEnabled',
    value: boolean
  ) => void;
}

const Header: React.FC<HeaderProps> = ({ activeSection, lastUpdate, onRefresh, settings, onToggleSetting }) => {
  const [showNotifications, setShowNotifications] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const [liveActive, setLiveActive] = useState(false);
  const [unreadCount, setUnreadCount] = useState<number>(0);

  type Notif = { id: string; title: string; message: string; type?: 'info'|'success'|'warning'|'error'; time: string };
  const [notifications, setNotifications] = useState<Notif[]>([]);
  const initialUpdateSeen = useRef(false);

  // Notification preferences persisted to localStorage
  const [notifPrefs, setNotifPrefs] = useState<{ liveOdds: boolean; reports: boolean; valueBets: boolean }>(() => {
    return {
      liveOdds: (localStorage.getItem('notifs.prefs.liveOdds') ?? 'true') === 'true',
      reports: (localStorage.getItem('notifs.prefs.reports') ?? 'true') === 'true',
      valueBets: (localStorage.getItem('notifs.prefs.valueBets') ?? 'true') === 'true',
    };
  });

  useEffect(() => {
    localStorage.setItem('notifs.prefs.liveOdds', String(notifPrefs.liveOdds));
  }, [notifPrefs.liveOdds]);
  useEffect(() => {
    localStorage.setItem('notifs.prefs.reports', String(notifPrefs.reports));
  }, [notifPrefs.reports]);
  useEffect(() => {
    localStorage.setItem('notifs.prefs.valueBets', String(notifPrefs.valueBets));
  }, [notifPrefs.valueBets]);

  // Mark live activity and push a simple notification whenever data refreshes
  useEffect(() => {
    if (!initialUpdateSeen.current) {
      initialUpdateSeen.current = true;
      return;
    }
    if (settings.liveAnimationsEnabled) {
      setLiveActive(true);
      const t = setTimeout(() => setLiveActive(false), 3000);
      return () => clearTimeout(t);
    }

    const when = lastUpdate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    const newNotif: Notif = {
      id: `${Date.now()}`,
      title: 'Data updated',
      message: `Application data refreshed at ${when} CST`,
      type: 'success',
      time: when,
    };
    setNotifications((prev) => [newNotif, ...prev].slice(0, 20));
  }, [lastUpdate, settings.liveAnimationsEnabled]);

  // Track last seen values to generate rich notifications
  const lastLiveOddsTs = useRef<string | null>(null);
  const lastReport800Ts = useRef<string | null>(null);
  const lastValueSignalsCount = useRef<number | null>(null);

  // Enrich notifications feed from concrete events
  useEffect(() => {
    if (!settings.notificationsEnabled) return;
    let cancelled = false;
    async function checkEvents() {
      const when = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      // Live Odds timestamp
      if (notifPrefs.liveOdds) {
        try {
          const lo: { timestamp?: string } = await api.games.getLiveOdds();
          const ts = lo?.timestamp ?? '';
          if (ts && lastLiveOddsTs.current && ts !== lastLiveOddsTs.current && !cancelled) {
            const n: Notif = {
              id: `liveodds-${Date.now()}`,
              title: 'Live odds updated',
              message: `New odds data at ${when} (timestamp changed)`,
              type: 'info',
              time: when,
            };
            setNotifications((prev) => [n, ...prev].slice(0, 50));
            setUnreadCount((c) => c + 1);
          }
          if (ts) lastLiveOddsTs.current = ts;
        } catch {
          // ignore
        }
      }

      // Morning reports readiness (use 8:00 as representative)
      if (notifPrefs.reports) {
        try {
          const r: { timestamp?: string; generated_at?: string; last_updated?: string } = await api.reports.get800Report();
          const ts = r?.timestamp || r?.generated_at || r?.last_updated || '';
          if (ts && lastReport800Ts.current && ts !== lastReport800Ts.current && !cancelled) {
            const n: Notif = {
              id: `report-${Date.now()}`,
              title: 'Report ready (8:00)',
              message: `New morning report published at ${when}`,
              type: 'success',
              time: when,
            };
            setNotifications((prev) => [n, ...prev].slice(0, 50));
            setUnreadCount((c) => c + 1);
          }
          if (ts) lastReport800Ts.current = ts;
        } catch {
          // ignore
        }
      }

      // Value bet signals
      if (notifPrefs.valueBets) {
        try {
          const b: { count?: number; recommendations?: unknown[] } | null = await api.betting.getRecommendations();
          const count = b?.count ?? (b?.recommendations ? b.recommendations.length : 0);
          if (
            count !== null &&
            lastValueSignalsCount.current !== null &&
            count !== lastValueSignalsCount.current &&
            !cancelled
          ) {
            const n: Notif = {
              id: `value-${Date.now()}`,
              title: 'Value bet signals updated',
              message: count > (lastValueSignalsCount.current ?? 0)
                ? `New signals available: ${count}`
                : `Signals changed: now ${count}`,
              type: 'warning',
              time: when,
            };
            setNotifications((prev) => [n, ...prev].slice(0, 50));
            setUnreadCount((c) => c + 1);
          }
          lastValueSignalsCount.current = count;
        } catch {
          // ignore
        }
      }
    }
    checkEvents();
    return () => {
      cancelled = true;
    };
  }, [lastUpdate, settings.notificationsEnabled, notifPrefs.liveOdds, notifPrefs.reports, notifPrefs.valueBets]);
  const getSectionTitle = (section: string) => {
    switch (section) {
      case 'dashboard': return 'NBA Analytics Dashboard';
      case 'reports': return 'Daily Reports Center';
      case 'bulls': return 'Chicago Bulls Analysis';
      case 'betting': return 'Betting Intelligence Hub';
      case 'odds': return 'Live Odds Monitor';
      case 'players': return 'Przeglądarka Zawodników';
      case 'analytics': return 'Advanced Analytics';
      default: return 'NBA Analytics';
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <header className="bg-gray-900/40 backdrop-blur-sm border-b border-gray-700/60 px-6 py-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">{getSectionTitle(activeSection)}</h1>
          {/* Compatibility marker for tests and screen readers */}
          <span className="sr-only">NBA Analysis & Betting System</span>
          <p className="text-gray-400 text-sm mt-1">
            Last updated: {formatTime(lastUpdate)} CST
          </p>
        </div>

        <div className="flex items-center space-x-4">
          {/* Live Status */}
          <div className="flex items-center space-x-2 glass-card px-3 py-2">
            <div className={`w-2 h-2 bg-green-400 rounded-full ${liveActive ? 'animate-pulse' : ''}`}></div>
            <span className="text-sm text-gray-300">Live Data</span>
          </div>

          {/* Refresh Button */}
          <button
            onClick={onRefresh}
            className="glass-card p-2 hover:bg-white/10 transition-colors duration-200"
            title="Refresh Data"
            aria-label="Refresh data"
          >
            <RefreshCw className="w-5 h-5 text-gray-400 hover:text-white" />
          </button>

          {/* Notifications */}
          <button 
            className="glass-card p-2 hover:bg-white/10 transition-colors duration-200 relative"
            onClick={() => {
              setShowNotifications(v => !v);
              setShowSettings(false);
              setShowProfile(false);
              setUnreadCount(0); // mark as read when opening
            }}
            aria-haspopup="true"
            title="Notifications"
          >
            <Bell className="w-5 h-5 text-gray-400 hover:text-white" />
            {unreadCount > 0 && (
              <div className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 bg-red-600 text-white text-[10px] leading-4 rounded-full flex items-center justify-center shadow-lg">
                {unreadCount > 9 ? '9+' : unreadCount}
              </div>
            )}
          </button>
          {showNotifications && createPortal(
            <div className="fixed inset-0 z-[999999]" onClick={() => setShowNotifications(false)}>
              <div className="absolute right-4 sm:right-10 md:right-28 top-16 w-[92vw] sm:w-80 bg-gray-900 border border-gray-700/60 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-4 border-b border-gray-700/50">
                  <div className="text-sm font-semibold text-white flex items-center justify-between">
                    <span>Live Notifications</span>
                    <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                  </div>
                </div>
                <div className="p-4 space-y-3 max-h-64 overflow-y-auto">
                  {notifications.length === 0 && (
                    <div className="p-3 bg-gray-800 border border-gray-700 rounded">
                      <div className="text-sm text-gray-300">No notifications yet</div>
                    </div>
                  )}
                  {notifications.map((n) => (
                    <div key={n.id} className="p-3 bg-gray-800 border border-gray-700 rounded">
                      <div className="text-sm text-white font-medium">{n.title}</div>
                      <div className="text-xs text-gray-400 mt-1">{n.message}</div>
                    </div>
                  ))}
                </div>
                <div className="p-3 border-t border-gray-700/50 text-right">
                  <button className="text-xs text-gray-400 hover:text-white transition-colors" onClick={() => setShowNotifications(false)}>Close</button>
                </div>
              </div>
            </div>,
            document.body
          )}

          {/* Settings */}
          <button 
            className="glass-card p-2 hover:bg-white/10 transition-colors duration-200"
            onClick={() => {
              setShowSettings(v => !v);
              setShowNotifications(false);
              setShowProfile(false);
            }}
            aria-haspopup="true"
            title="Settings"
          >
            <Settings className="w-5 h-5 text-gray-400 hover:text-white" />
          </button>
          {showSettings && createPortal(
            <div className="fixed inset-0 z-[999999]" onClick={() => setShowSettings(false)}>
              <div className="absolute right-2 sm:right-10 md:right-16 top-16 w-[92vw] sm:w-72 bg-gray-900 border border-gray-700/60 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-4 border-b border-gray-700/50">
                  <div className="text-sm font-semibold text-white">Quick Settings</div>
                </div>
                <div className="p-4 space-y-4">
                  {/* Core toggles tied to real behavior */}
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Live Data Animations</span>
                    <input
                      type="checkbox"
                      className="rounded bg-gray-700 border-gray-600"
                      checked={settings.liveAnimationsEnabled}
                      onChange={(e) => onToggleSetting('liveAnimationsEnabled', e.target.checked)}
                    />
                  </label>
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Notifications Enabled</span>
                    <input
                      type="checkbox"
                      className="rounded bg-gray-700 border-gray-600"
                      checked={settings.notificationsEnabled}
                      onChange={(e) => onToggleSetting('notificationsEnabled', e.target.checked)}
                    />
                  </label>

                  {/* Notification preferences */}
                  <div className="border-t border-gray-700/50 pt-3">
                    <div className="text-xs uppercase tracking-wide text-gray-400 mb-2">Notification Preferences</div>
                    <label className="flex items-center justify-between mb-2">
                      <span className="text-gray-300">Live odds updates</span>
                      <input
                        type="checkbox"
                        className="rounded bg-gray-700 border-gray-600"
                        checked={notifPrefs.liveOdds}
                        onChange={(e) => setNotifPrefs((p) => ({ ...p, liveOdds: e.target.checked }))}
                        disabled={!settings.notificationsEnabled}
                      />
                    </label>
                    <label className="flex items-center justify-between mb-2">
                      <span className="text-gray-300">Reports ready</span>
                      <input
                        type="checkbox"
                        className="rounded bg-gray-700 border-gray-600"
                        checked={notifPrefs.reports}
                        onChange={(e) => setNotifPrefs((p) => ({ ...p, reports: e.target.checked }))}
                        disabled={!settings.notificationsEnabled}
                      />
                    </label>
                    <label className="flex items-center justify-between">
                      <span className="text-gray-300">Value bet signals</span>
                      <input
                        type="checkbox"
                        className="rounded bg-gray-700 border-gray-600"
                        checked={notifPrefs.valueBets}
                        onChange={(e) => setNotifPrefs((p) => ({ ...p, valueBets: e.target.checked }))}
                        disabled={!settings.notificationsEnabled}
                      />
                    </label>
                  </div>
                </div>
                <div className="p-3 border-t border-gray-700/50 text-right">
                  <button className="text-xs text-gray-400 hover:text-white transition-colors" onClick={() => setShowSettings(false)}>Close</button>
                </div>
              </div>
            </div>,
            document.body
          )}

          {/* User Profile */}
          <button 
            className="flex items-center space-x-2 glass-card px-3 py-2 hover:bg-white/10 transition-colors duration-200"
            onClick={() => {
              setShowProfile(v => !v);
              setShowNotifications(false);
              setShowSettings(false);
            }}
            aria-haspopup="true"
            title="Profile"
          >
            <Users className="w-5 h-5 text-gray-400" />
            <span className="text-sm text-gray-300">Analyst</span>
          </button>
          {showProfile && createPortal(
            <div className="fixed inset-0 z-[999999]" onClick={() => setShowProfile(false)}>
              <div className="absolute right-2 sm:right-4 top-16 w-[92vw] sm:w-56 bg-gray-900 border border-gray-700/60 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-2">
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Profile Settings</button>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Preferences</button>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Analytics History</button>
                  <div className="border-t border-gray-700/50 my-2"></div>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-400 hover:text-white transition-colors" onClick={() => setShowProfile(false)}>Close</button>
                </div>
              </div>
            </div>,
            document.body
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;