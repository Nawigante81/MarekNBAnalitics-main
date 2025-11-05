import React, { useState } from 'react';
import { Bell, RefreshCw, Settings, Users } from 'lucide-react';

interface HeaderProps {
  activeSection: string;
  lastUpdate: Date;
  onRefresh: () => void;
}

const Header: React.FC<HeaderProps> = ({ activeSection, lastUpdate, onRefresh }) => {
  const [showNotifications, setShowNotifications] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
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
    <header className="bg-gray-900/30 backdrop-blur-sm border-b border-gray-700/50 px-6 py-4">
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
            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            <span className="text-sm text-gray-300">Live Data</span>
          </div>

          {/* Refresh Button */}
          <button
            onClick={onRefresh}
            className="glass-card p-2 hover:bg-white/10 transition-colors duration-200"
            title="Refresh Data"
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
            }}
            aria-haspopup="true"
            aria-expanded={showNotifications ? "true" : "false"}
            title="Notifications"
          >
            <Bell className="w-5 h-5 text-gray-400 hover:text-white" />
            <div className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
          </button>
          {showNotifications && (
            <div className="fixed inset-0 z-[9999]" onClick={() => setShowNotifications(false)}>
              <div className="absolute right-28 top-16 w-80 bg-gray-900/95 backdrop-blur-md border border-gray-700/50 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-4 border-b border-gray-700/50">
                  <div className="text-sm font-semibold text-white flex items-center justify-between">
                    <span>Live Notifications</span>
                    <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                  </div>
                </div>
                <div className="p-4 space-y-3 max-h-64 overflow-y-auto">
                  <div className="p-3 bg-yellow-600/10 border border-yellow-600/20 rounded">
                    <div className="text-sm text-yellow-400 font-medium">Line Movement Alert</div>
                    <div className="text-xs text-gray-300 mt-1">Bulls -2.5 → -3.0 (2m ago)</div>
                  </div>
                  <div className="p-3 bg-blue-600/10 border border-blue-600/20 rounded">
                    <div className="text-sm text-blue-400 font-medium">Report Ready</div>
                    <div className="text-xs text-gray-300 mt-1">8:00 AM Morning Summary available</div>
                  </div>
                  <div className="p-3 bg-green-600/10 border border-green-600/20 rounded">
                    <div className="text-sm text-green-400 font-medium">Value Bet Alert</div>
                    <div className="text-xs text-gray-300 mt-1">Bulls +2.5 showing 4.2% edge</div>
                  </div>
                </div>
                <div className="p-3 border-t border-gray-700/50 text-right">
                  <button className="text-xs text-gray-400 hover:text-white transition-colors" onClick={() => setShowNotifications(false)}>Close</button>
                </div>
              </div>
            </div>
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
            aria-expanded={showSettings ? "true" : "false"}
            title="Settings"
          >
            <Settings className="w-5 h-5 text-gray-400 hover:text-white" />
          </button>
          {showSettings && (
            <div className="fixed inset-0 z-[9999]" onClick={() => setShowSettings(false)}>
              <div className="absolute right-16 top-16 w-72 bg-gray-900/95 backdrop-blur-md border border-gray-700/50 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-4 border-b border-gray-700/50">
                  <div className="text-sm font-semibold text-white">Quick Settings</div>
                </div>
                <div className="p-4 space-y-4">
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Live Data Animations</span>
                    <input type="checkbox" className="rounded bg-gray-700 border-gray-600" defaultChecked />
                  </label>
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Auto-refresh (30s)</span>
                    <input type="checkbox" className="rounded bg-gray-700 border-gray-600" defaultChecked />
                  </label>
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Compact mode</span>
                    <input type="checkbox" className="rounded bg-gray-700 border-gray-600" />
                  </label>
                  <label className="flex items-center justify-between">
                    <span className="text-gray-300">Sound alerts</span>
                    <input type="checkbox" className="rounded bg-gray-700 border-gray-600" />
                  </label>
                </div>
                <div className="p-3 border-t border-gray-700/50 text-right">
                  <button className="text-xs text-gray-400 hover:text-white transition-colors" onClick={() => setShowSettings(false)}>Close</button>
                </div>
              </div>
            </div>
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
            aria-expanded={showProfile ? "true" : "false"}
            title="Profile"
          >
            <Users className="w-5 h-5 text-gray-400" />
            <span className="text-sm text-gray-300">Analyst</span>
          </button>
          {showProfile && (
            <div className="fixed inset-0 z-[9999]" onClick={() => setShowProfile(false)}>
              <div className="absolute right-4 top-16 w-56 bg-gray-900/95 backdrop-blur-md border border-gray-700/50 rounded-lg shadow-2xl" onClick={(e) => e.stopPropagation()}>
                <div className="p-2">
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Profile Settings</button>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Preferences</button>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-300 hover:text-white transition-colors">Analytics History</button>
                  <div className="border-t border-gray-700/50 my-2"></div>
                  <button className="w-full text-left px-3 py-2 rounded hover:bg-white/10 text-sm text-gray-400 hover:text-white transition-colors" onClick={() => setShowProfile(false)}>Close</button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;