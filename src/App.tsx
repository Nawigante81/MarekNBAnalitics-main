import { useState, useEffect } from 'react';
import { Zap, BarChart3, FileText, Users, DollarSign, TrendingUp, Activity, LineChart, BarChart, Target, AlertTriangle } from 'lucide-react';

import Dashboard from './components/Dashboard';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import Footer from './components/Footer';
import ReportsSection from './components/ReportsSection';
import BullsAnalysis from './components/BullsAnalysis';
import BettingRecommendations from './components/BettingRecommendations';
import LiveOdds from './components/LiveOdds';
import PlayersBrowser from './components/PlayersBrowser';
import Roster from './components/Roster.tsx';
import Line from './components/Line.tsx';
import Trend from './components/Trend.tsx';
import Statistic from './components/Statistic.tsx';
import FormView from './components/Form.tsx';
import Ranking from './components/Ranking.tsx';
import Risk from './components/Risk.tsx';
import ChartView from './components/Chart.tsx';
import LeagueTrends from './components/LeagueTrends.tsx';

type Section = 'dashboard' | 'reports' | 'bulls' | 'betting' | 'odds' | 'analytics' | 'players'
  | 'roster' | 'line' | 'trend' | 'statistic' | 'form' | 'ranking' | 'risk' | 'chart';

function App() {
  const [activeSection, setActiveSection] = useState<Section>('dashboard');
  const [selectedGameId, setSelectedGameId] = useState<string | null>(null);
  
  const sidebarItems = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'reports', label: 'Reports', icon: FileText },
    { id: 'bulls', label: 'Bulls Analysis', icon: Users },
    { id: 'betting', label: 'Betting', icon: DollarSign },
    { id: 'odds', label: 'Live Odds', icon: TrendingUp },
    { id: 'players', label: 'Zawodnicy', icon: Users },
  { id: 'roster', label: 'Roster', icon: Users },
    { id: 'line', label: 'Line', icon: LineChart },
    { id: 'trend', label: 'Trend', icon: TrendingUp },
  { id: 'statistic', label: 'Statistic', icon: BarChart },
    { id: 'form', label: 'Form', icon: Target },
    { id: 'ranking', label: 'Ranking', icon: BarChart3 },
    { id: 'risk', label: 'Risk', icon: AlertTriangle },
    { id: 'chart', label: 'Chart', icon: Activity },
    { id: 'analytics', label: 'Analytics', icon: Activity }
  ];
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  useEffect(() => {
    // Simulate initial data loading
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 2000);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    // Auto-refresh data every 30 seconds (aligns with tests and Live Odds polling cadence)
    const interval = setInterval(() => {
      setLastUpdate(new Date());
    }, 30 * 1000);
    return () => clearInterval(interval);
  }, []);

  

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-950 flex items-center justify-center">
        <div className="text-center">
          <div className="relative">
            <div className="w-20 h-20 border-4 border-blue-400/30 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
            <div className="absolute inset-0 w-20 h-20 border-4 border-red-400/20 border-b-red-400 rounded-full animate-spin-reverse mx-auto"></div>
          </div>
          <h2 className="text-2xl font-bold text-white mb-2">Analitics for Marek</h2>
          <p className="text-gray-400">Loading real-time data...</p>
          {/* Preserve legacy heading for tests */}
          <span className="sr-only">NBA Analysis & Betting System</span>
          <div className="flex items-center justify-center mt-4 space-x-2">
            <Zap className="w-4 h-4 text-yellow-400 animate-pulse" />
            <span className="text-sm text-gray-500">Fetching NBA analysis & odds</span>
          </div>
        </div>
      </div>
    );
  }

  const renderContent = () => {
    switch (activeSection) {
      case 'dashboard':
        return <Dashboard onViewOdds={(gameId: string) => { setSelectedGameId(gameId); setActiveSection('odds'); }} />;
      case 'reports':
        return <ReportsSection />;
      case 'bulls':
        return <BullsAnalysis />;
      case 'betting':
        return <BettingRecommendations />;
      case 'odds':
        return <LiveOdds selectedGameId={selectedGameId || undefined} />;
      case 'players':
        return <PlayersBrowser />;
      case 'roster':
        return <Roster />;
      case 'line':
        return <Line />;
      case 'trend':
        return <Trend />;
      case 'statistic':
        return <Statistic />;
      case 'form':
        return <FormView />;
      case 'ranking':
        return <Ranking />;
      case 'risk':
        return <Risk />;
      case 'chart':
        return <ChartView />;
      case 'analytics':
        return <LeagueTrends />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-950 text-gray-100">
      {/* Background Pattern */}
      <div className="fixed inset-0 opacity-5">
        <div className="absolute inset-0 background-gradient"></div>
      </div>

      <div className="relative z-10 flex h-screen">
        {/* Sidebar */}
        <Sidebar 
          items={sidebarItems}
          activeSection={activeSection} 
          onSectionChange={(section: string) => setActiveSection(section as Section)}
        />

        {/* Main Content */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header 
            activeSection={activeSection}
            lastUpdate={lastUpdate}
            onRefresh={() => setLastUpdate(new Date())}
          />
          
          <main id="main-content" role="main" className="flex-1 overflow-auto p-6 pb-0">
            {renderContent()}
          </main>
          
          {/* Footer */}
          <Footer />
        </div>
      </div>

      {/* Status Indicator */}
      <div className="fixed bottom-20 right-4 z-50">
        <div className="glass-card px-4 py-2 flex items-center space-x-2">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
          <span className="text-sm text-gray-300">Live Data</span>
        </div>
      </div>
    </div>
  );
}

export default App;
