# Frontend Integration - Required Changes

## 1. Environment Configuration
Create `.env` file in project root:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_API_BASE_URL=http://localhost:8000
```

## 2. API Integration Layer
Create `src/services/api.ts`:
```typescript
const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export const api = {
  // Teams
  getTeams: () => fetch(`${API_BASE}/api/teams`).then(r => r.json()),
  
  // Players  
  getPlayers: (filters?: {team?: string, position?: string}) => 
    fetch(`${API_BASE}/api/players?${new URLSearchParams(filters)}`).then(r => r.json()),
    
  getTeamPlayers: (teamAbbrev: string) => 
    fetch(`${API_BASE}/api/teams/${teamAbbrev}/players`).then(r => r.json()),
  
  // Games & Odds
  getTodayGames: () => fetch(`${API_BASE}/api/games/today`).then(r => r.json()),
  getGameOdds: (gameId: string) => fetch(`${API_BASE}/api/odds/${gameId}`).then(r => r.json()),
  
  // Reports
  get750Report: () => fetch(`${API_BASE}/api/reports/750am`).then(r => r.json()),
  get800Report: () => fetch(`${API_BASE}/api/reports/800am`).then(r => r.json()),
  get1100Report: () => fetch(`${API_BASE}/api/reports/1100am`).then(r => r.json()),
  
  // Bulls Analysis
  getBullsAnalysis: () => fetch(`${API_BASE}/api/bulls-analysis`).then(r => r.json()),
  
  // Betting
  getBettingRecommendations: () => fetch(`${API_BASE}/api/betting-recommendations`).then(r => r.json()),
  getArbitrageOpportunities: () => fetch(`${API_BASE}/api/arbitrage-opportunities`).then(r => r.json())
};
```

## 3. Component Updates Needed

### Dashboard.tsx
- Replace mock data with `api.getTodayGames()`, `api.getTeams()`  
- Add real-time refresh functionality
- Connect Bulls spotlight to `api.getBullsAnalysis()`

### BullsAnalysis.tsx  
- Replace hardcoded player stats with `api.getTeamPlayers('CHI')`
- Connect to real Bulls analysis endpoint
- Show actual Basketball-Reference scraped data

### BettingRecommendations.tsx
- Replace mock bets with `api.getBettingRecommendations()` 
- Connect Kelly calculator to backend endpoint
- Show real arbitrage opportunities

### LiveOdds.tsx
- Connect to `api.getGameOdds()` for each game
- Implement real-time odds refresh (WebSocket or polling)
- Show actual bookmaker data from The Odds API

### ReportsSection.tsx  
- Connect to report endpoints (750am, 800am, 1100am)
- Show real generated reports instead of mock content

## 4. Missing Button Implementations

### Header.tsx - Settings Button
Add settings modal/dropdown with:
- Refresh interval configuration  
- Notification preferences
- Theme settings
- API key management

### Header.tsx - Notifications Button  
Add notification system:
- Line movement alerts
- Bulls game notifications  
- Betting recommendation alerts
- Report generation status

## 5. Real-time Data Integration

### Add React Query/SWR for:
- Automatic data refresh
- Background sync
- Cache management  
- Error handling

### WebSocket Implementation:
- Live odds updates
- Real-time line movements
- Push notifications for alerts

## 6. Error Handling & Loading States
- Add proper error boundaries
- Show meaningful error messages when API fails  
- Implement retry logic for failed requests
- Add skeleton loaders during data fetch

## 7. Supabase Direct Integration (Alternative)
Instead of going through FastAPI, components could connect directly to Supabase:
- Install @supabase/supabase-js
- Create supabase client in components  
- Query teams/players/games tables directly
- Requires RLS (Row Level Security) setup