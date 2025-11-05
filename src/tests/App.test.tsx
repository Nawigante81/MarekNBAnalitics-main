import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from '../App';

// Mock fetch API
global.fetch = vi.fn();

const mockFetch = (data: any, ok = true) => {
  return Promise.resolve({
    ok,
    json: () => Promise.resolve(data),
  });
};

describe('App Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders without crashing', () => {
    render(<App />);
    expect(screen.getByText('NBA Analysis & Betting System')).toBeInTheDocument();
  });

  it('displays navigation items', () => {
    render(<App />);
    
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Reports')).toBeInTheDocument();
    expect(screen.getByText('Bulls Analysis')).toBeInTheDocument();
    expect(screen.getByText('Betting')).toBeInTheDocument();
    expect(screen.getByText('Live Odds')).toBeInTheDocument();
  });

  it('switches sections when navigation items are clicked', async () => {
    render(<App />);
    
    const reportsButton = screen.getByText('Reports');
    fireEvent.click(reportsButton);
    
    await waitFor(() => {
      expect(screen.getByText('NBA Reports')).toBeInTheDocument();
    });
  });

  it('shows loading states', async () => {
    // Mock API call that takes time
    (fetch as any).mockImplementation(() => 
      new Promise(resolve => setTimeout(() => resolve(mockFetch({})), 100))
    );

    render(<App />);
    
    // Should show loading indicator
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });
});

describe('Dashboard Section', () => {
  beforeEach(() => {
    (fetch as any).mockResolvedValue(mockFetch({
      games: [
        {
          id: '1',
          home_team: 'Chicago Bulls',
          away_team: 'Los Angeles Lakers',
          game_date: '2024-01-15T20:00:00Z',
          status: 'scheduled'
        }
      ]
    }));
  });

  it('displays game information', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Chicago Bulls')).toBeInTheDocument();
      expect(screen.getByText('Los Angeles Lakers')).toBeInTheDocument();
    });
  });
});

describe('Bulls Analysis Section', () => {
  beforeEach(() => {
    (fetch as any).mockResolvedValue(mockFetch({
      last_game_recap: {
        opponent: 'Detroit Pistons',
        result: 'W 112-108',
        key_performances: ['DeMar DeRozan: 28 PTS, 6 REB, 5 AST']
      },
      current_form_analysis: {
        record_l10: '6-4',
        ats_l10: '7-3'
      }
    }));
  });

  it('displays Bulls analysis data', async () => {
    render(<App />);
    
    const bullsButton = screen.getByText('Bulls Analysis');
    fireEvent.click(bullsButton);
    
    await waitFor(() => {
      expect(screen.getByText('Bulls Analytics')).toBeInTheDocument();
    });
  });
});

describe('Betting Recommendations Section', () => {
  beforeEach(() => {
    (fetch as any).mockResolvedValue(mockFetch({
      conservative_plays: {
        plays: [
          {
            bet: 'Celtics -5.5',
            odds: -110,
            confidence: 82,
            reasoning: 'Home court advantage'
          }
        ]
      }
    }));
  });

  it('displays betting recommendations', async () => {
    render(<App />);
    
    const bettingButton = screen.getByText('Betting');
    fireEvent.click(bettingButton);
    
    await waitFor(() => {
      expect(screen.getByText('Betting Recommendations')).toBeInTheDocument();
    });
  });
});

describe('Reports Section', () => {
  beforeEach(() => {
    (fetch as any).mockResolvedValue(mockFetch({
      timestamp: '2024-01-15T07:50:00Z',
      report_type: '750am_previous_day',
      yesterday_results: {
        focus_teams_performance: {
          bulls: { result: 'W 112-108', ats: 'L', ou: 'O' }
        }
      }
    }));
  });

  it('displays report sections', async () => {
    render(<App />);
    
    const reportsButton = screen.getByText('Reports');
    fireEvent.click(reportsButton);
    
    await waitFor(() => {
      expect(screen.getByText('NBA Reports')).toBeInTheDocument();
      expect(screen.getByText('7:50 AM Report')).toBeInTheDocument();
      expect(screen.getByText('8:00 AM Report')).toBeInTheDocument();
      expect(screen.getByText('11:00 AM Report')).toBeInTheDocument();
    });
  });
});

describe('Error Handling', () => {
  it('handles API errors gracefully', async () => {
    (fetch as any).mockRejectedValue(new Error('API Error'));
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });

  it('handles network failures', async () => {
    (fetch as any).mockResolvedValue(mockFetch({}, false));
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/failed to load/i)).toBeInTheDocument();
    });
  });
});

describe('Auto-refresh Functionality', () => {
  it('automatically refreshes data', async () => {
    vi.useFakeTimers();
    
    (fetch as any).mockResolvedValue(mockFetch({ games: [] }));
    
    render(<App />);
    
    // Fast-forward time to trigger refresh
    vi.advanceTimersByTime(30000);
    
    expect(fetch).toHaveBeenCalledTimes(2); // Initial + refresh
    
    vi.useRealTimers();
  });
});

describe('Responsive Design', () => {
  it('adapts to mobile viewport', () => {
    // Mock mobile viewport
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 375,
    });

    render(<App />);
    
    // Should render mobile-friendly layout
    expect(screen.getByText('NBA Analysis & Betting System')).toBeInTheDocument();
  });
});