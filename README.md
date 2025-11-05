# 🏀 NBA Analysis & Betting System

**Advanced NBA Analytics & Betting Intelligence Platform**

A comprehensive, professional-grade NBA analysis and betting system with a focus on the Chicago Bulls. This platform provides real-time data processing, advanced statistical analysis, automated reporting, and intelligent betting recommendations using Kelly Criterion optimization.

![NBA Analysis Dashboard](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green)
![React](https://img.shields.io/badge/React-18+-blue)

## Architecture Overview

- **Backend**: FastAPI with async/await for high-performance data handling
- **Database**: Supabase PostgreSQL for persistent data storage
- **Data Sources**: Basketball-Reference (games/teams), The Odds API (real-time odds)
- **Scheduling**: APScheduler for automated report generation at specific times
- **Containerization**: Docker for consistent deployment

## Key Features

### 1. Automated Data Scraping
- **Teams**: Basketball-Reference web scraper fetches NBA team data
- **Games**: Real-time game schedules and results via The Odds API
- **Odds**: Multi-bookmaker odds aggregation (DraftKings, BetMGM, etc.)
- **Schedule**: Runs every 6 hours with background loop, includes startup sync

### 2. Focus Teams Analysis
Primary analysis focus on 9 key teams:
- Celtics, Wolves, Thunder, Magic, Cavs
- Kings, Rockets, Knicks, **Bulls** (with per-player breakdown)

### 3. Three Daily Reports (Westchester, IL timezone)

#### 7:50 AM Report - Previous Day Analysis
- **Wyniki vs closing line**: Compare final results against closing lines (ATS, O/U)
- **Top 3 trendy**: Identify teams consistently over/under Vegas expectations
- **Bulls gracz-po-graczu**: Individual player stats (PTS/REB/AST), role, minutes
- **Ryzyka**: Key insights for next day trading

#### 8:00 AM Report - Morning Summary
- **Wyniki wczoraj**: 1-line summary per focus team (result, ATS, O/U)
- **Trendy 7-dniowe**: 7-day trend analysis (tempo, OffRtg, DefRtg, 3PT%, FT%)
- **Bulls zawodnicy**: Current form (last 5 games), minutes, role changes
- **Wnioski bukmacherskie**: 2-3 directional trades (e.g., "X under look", "Y rebounds uptick")
- **Prośba o kursy**: Action required - upload DraftKings/BetMGM screenshots

#### 11:00 AM Report - Game-Day Scouting
- **Kto gra dziś**: Full slate with game times + injury/absence status
- **Match-up notes**: Tempo, positional advantages, inside/outside trends
- **Bulls arkusz**:
  - Last game recap
  - Updated player form (last 5 games)
  - Positional matchups
  - Initial lean (O/U and side)
- **Propozycje zakładów**:
  - General parlay (3-5 legs, low-risk)
  - Bulls parlay (2-5 legs, player props + game lines)
  - Conservative alternatives
- **Ryzyka**: Late scratches, minutes restrictions, B2B, travel, line movements

## Project Structure

```
.
├── backend/
│   ├── main.py                 # FastAPI app with lifespan, scheduler, endpoints
│   ├── scrapers.py             # Data scraping logic (async)
│   ├── reports.py              # Report generation module
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Container configuration
│   ├── .env.example            # Example environment variables
│   └── __pycache__/
├── docker-compose.yml          # Multi-container orchestration
├── .env                        # Local environment (NOT committed)
├── .gitignore
├── README.md
└── [frontend files...]
```

## 🚀 Quick Start (5 minutes)

### Option 1: Automated Installation (Recommended)

**Windows:**

```cmd
setup.bat
start.bat
```

**Linux/macOS:**

```bash
chmod +x setup.sh start.sh
./setup.sh
./start.sh
```

### Option 2: Docker Deployment

**Windows:**

```cmd
docker-start.bat
```

**Linux/macOS:**

```bash
docker-compose up -d
```

### 📖 Detailed Installation Guides

| Platform | Guide | Difficulty |
|----------|-------|------------|
| **Windows 11/10** | [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md) | ⭐ Easy |
| **Ubuntu/Debian** | [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) | ⭐ Easy |
| **Raspberry Pi 4** | [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) | ⭐⭐ Medium |
| **Docker (Any OS)** | [README.md](#docker-deployment) | ⭐ Easy |
| **All Platforms** | [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) | ⭐ Easy |

## Setup & Installation

### Prerequisites

- **Node.js 18+** and **Python 3.8+** (if not using Docker)
- **Supabase project** with API keys
- **The Odds API key** (free tier: 500 requests/month)
- **Docker** (optional, for containerized deployment)

### 1. Environment Configuration

The setup scripts will create `.env` files automatically, but you need to add your API keys:

```env
# Required API Keys
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
ODDS_API_KEY=your-odds-api-key
```

### 2. Supabase Setup

Create the following tables in your Supabase project:

#### `teams` table
- `id` (uuid, primary key)
- `abbreviation` (text, UNIQUE) - e.g., "CHI", "LAL"
- `full_name` (text)
- `name` (text)
- `city` (text)
- `created_at` (timestamptz)

#### `games` table
- `id` (text, primary key)
- `sport_key` (text)
- `sport_title` (text)
- `commence_time` (timestamptz)
- `home_team` (text)
- `away_team` (text)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

#### `odds` table
- `id` (uuid, primary key)
- `game_id` (text, foreign key to games.id)
- `bookmaker_key` (text)
- `bookmaker_title` (text)
- `last_update` (timestamptz)
- `market_type` (text) - "h2h", "spread", or "totals"
- `team` (text)
- `outcome_name` (text)
- `point` (numeric)
- `price` (numeric)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

### 3. Build & Run

```bash
# Build and start the backend
docker compose up --build -d backend

# View logs
docker compose logs -f backend

# Check health
curl http://localhost:8000/health

# Stop containers
docker compose down
```

## API Endpoints

### Health & Status
- `GET /health` - Health check
- `GET /api/status` - Application status and configuration

### Data Access
- `GET /api/teams` - Get all teams
- `GET /api/games/today` - Get today's games
- `GET /api/odds/{game_id}` - Get odds for a specific game

### Reports (Generated automatically at scheduled times)
- `GET /api/reports/750am` - Previous day analysis
- `GET /api/reports/800am` - Morning summary
- `GET /api/reports/1100am` - Game-day scouting

## Data Sources

### Basketball-Reference
- **URL**: https://www.basketball-reference.com
- **Data**: Team rosters, game schedules, historical results
- **Update**: On-demand via scheduler (6-hour interval)

### The Odds API
- **URL**: https://www.the-odds-api.com
- **Data**: Real-time odds from major bookmakers (DraftKings, BetMGM, Draftkings, etc.)
- **Markets**: Head-to-head (H2H), spread, totals
- **Update**: On-demand via scheduler (6-hour interval)

## Data Flow

```
1. Application Startup
   ├── Initialize Supabase client
   ├── Run initial data scrape
   ├── Start background scraper loop (6-hour interval)
   └── Initialize APScheduler for report generation

2. Background Scraper Loop (Continuous)
   ├── Fetch teams from Basketball-Reference
   ├── Save/upsert teams to Supabase
   ├── Fetch games and odds from The Odds API
   ├── Save/upsert games to Supabase
   └── Save/upsert odds to Supabase

3. Report Generation (Scheduled)
   ├── 7:50 AM: Generate previous day analysis
   ├── 8:00 AM: Generate morning summary
   ├── 11:00 AM: Generate game-day scouting
   └── Reports available via API endpoints

4. API Requests
   └── Clients query endpoints for data and reports
```

## Development

### Local Testing

```bash
# Install dependencies
pip install -r backend/requirements.txt

# Set environment variables
export VITE_SUPABASE_URL="..."
export VITE_SUPABASE_ANON_KEY="..."
export ODDS_API_KEY="..."

# Run locally (with auto-reload)
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Adding New Reports or Scrapers

1. **New Scraper**: Add function to `backend/scrapers.py`
2. **New Report**: Add method to `NBAReportGenerator` class in `backend/reports.py`
3. **Schedule New Report**: Add `scheduler.add_job()` call in `main.py` lifespan

### Database Queries

Use the Supabase dashboard SQL editor for debugging:

```sql
-- Check teams
SELECT * FROM teams WHERE abbreviation LIKE 'CHI%';

-- Check today's games
SELECT * FROM games WHERE commence_time >= NOW() AND commence_time < NOW() + INTERVAL '1 day';

-- Check odds for a game
SELECT * FROM odds WHERE game_id = 'xxxxx' AND market_type = 'spread';
```

## Troubleshooting

### Container won't start
- Check Docker daemon is running
- Verify `.env` file exists and has correct credentials
- Review logs: `docker compose logs backend`

### Scraper not running
- Ensure container is running: `docker compose ps`
- Check logs for errors: `docker compose logs -f backend`
- Verify API keys are valid (test with curl)

### No data in database
- Confirm Supabase tables exist with correct schema
- Check API key permissions in Supabase
- Manually test scraper: access API endpoints in browser

### Reports not generating at scheduled times
- Verify timezone is set correctly (America/Chicago)
- Check server time synchronization
- Review scheduler logs for job execution

## Performance Considerations

- **Scraper Interval**: 6 hours balances freshness vs. API rate limits
- **Report Generation**: One job per timezone, runs even if no data changes
- **Database Indexes**: Added on frequently queried columns (abbreviation, game_id, market_type)
- **Async Operations**: All I/O operations are non-blocking

## Future Enhancements

- [ ] Historical game results and final scores
- [ ] Player-level statistics and form tracking
- [ ] VegasInsider web scraping for closing lines
- [ ] Automatic parlay generation with Kelly criterion stake sizing
- [ ] Betting performance tracking and ROI metrics
- [ ] Alert system for value bets meeting criteria
- [ ] Frontend dashboard for report visualization
- [ ] PostgreSQL full-text search for historical analysis

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Framework | FastAPI | 0.104.1 |
| Server | Uvicorn | 0.24.0 |
| Database | Supabase (PostgreSQL) | - |
| Client | supabase-py | 2.4.0 |
| HTTP | httpx | 0.25.2 |
| Scraping | BeautifulSoup4 | 4.12.2 |
| Scheduling | APScheduler | 3.10.4 |
| Async | anyio | 4.1.1 |
| Container | Docker | - |

## Support & Maintenance

For issues or questions:
1. Check logs: `docker compose logs backend`
2. Verify API connectivity manually
3. Confirm Supabase schema matches expectations
4. Review endpoint responses with curl or Postman

## License

Proprietary - NBA Analysis System
