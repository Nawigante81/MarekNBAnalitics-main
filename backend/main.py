import os
import asyncio
import contextlib
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Response, Request, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import io, csv
import pandas as pd
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
import anyio
# Import supabase through isolated client to avoid conflicts
from supabase_client import create_isolated_supabase_client, get_supabase_config
from typing import Any as Client  # Use Any as Client placeholder to fix typing
from dotenv import load_dotenv
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
import pytz
from external_apis import fetch_nba_teams, fetch_nba_games, fetch_live_odds, fetch_nba_players, fetch_player_stats, fetch_player_by_id

# Temporarily use mock implementations to avoid httpx_socks conflicts with supabase
# These will be loaded dynamically when needed
def scrape_all_data(*args, **kwargs):
    """Mock scraper function - will be replaced with real implementation"""
    logger.info("Using mock scraper - anti-bot functionality disabled for now")
    return {}

class NBAReportGenerator:
    """Mock report generator - will be replaced with real implementation"""
    def __init__(self, supabase_client):
        self.supabase = supabase_client
        logger.info("Using mock report generator")
    
    async def generate_750am_report(self):
        return {"report_type": "750am_mock", "timestamp": datetime.now().isoformat()}
    
    async def generate_800am_report(self):
        return {"report_type": "800am_mock", "timestamp": datetime.now().isoformat()}
    
    async def generate_1100am_report(self):
        return {"report_type": "1100am_mock", "timestamp": datetime.now().isoformat()}
    
    async def _bulls_gameday_analysis(self):
        return {"mock": "bulls_analysis"}
    
    async def _comprehensive_betting_strategy(self):
        return {"mock": "betting_strategy"}
    
    def calculate_kelly_criterion(self, prob, odds):
        return max(0, min((prob * odds - 1) / (odds - 1) * 0.25, 0.25))
    
    def format_betting_slip(self, bets, stake):
        return {"mock": "betting_slip", "total_stake": stake}
    
    async def save_report(self, report, report_type):
        """Mock save report"""
        logger.info(f"Mock saving report: {report_type}")
        return True
        
        def calculate_roi_projection(self, history):
            return {"roi": 0, "total_bets": 0, "win_rate": 0}
        
        async def identify_arbitrage_opportunities(self, odds):
            return []

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _parse_ordering(order_by: str, order_dir: str, allowed: set[str]):
    cols = [c.strip() for c in (order_by or "").split(",") if c.strip()]
    dirs = [d.strip().lower() for d in (order_dir or "").split(",") if d.strip()]
    if cols and len(dirs) not in (0, len(cols)):
        raise HTTPException(status_code=400, detail="order_dir must provide a direction for each order_by column")
    for c in cols:
        if c not in allowed:
            raise HTTPException(status_code=400, detail=f"Unsupported order column: {c}")
    if not cols:
        return []
    if not dirs:
        dirs = ["asc"] * len(cols)
    return [(c, d == "desc") for c, d in zip(cols, dirs)]


def _clamp_limit(limit, default: int | None = None) -> int | None:
    if limit is None:
        return None if default is None else max(1, min(int(default), 500))
    try:
        val = int(limit)
    except Exception:
        val = default if default is not None else 50
    return max(1, min(val, 500))


def _build_pagination_links(request: Request, limit: int | None, offset: int, total: int | None, limit_param: str = "limit", offset_param: str = "offset") -> str | None:
    if limit is None:
        return None
    links = []
    scheme, netloc, path, query, frag = urlsplit(str(request.url))
    q = dict(parse_qsl(query, keep_blank_values=True))
    q[limit_param] = str(limit)

    # first
    q[offset_param] = "0"
    first_url = urlunsplit((scheme, netloc, path, urlencode(q), frag))
    links.append(f"<{first_url}>; rel=\"first\"")

    # prev
    if offset > 0:
        prev_off = max(0, offset - limit)
        q[offset_param] = str(prev_off)
        prev_url = urlunsplit((scheme, netloc, path, urlencode(q), frag))
        links.append(f"<{prev_url}>; rel=\"prev\"")

    # next
    if total is None or (offset + limit) < total:
        next_off = offset + limit
        q[offset_param] = str(next_off)
        next_url = urlunsplit((scheme, netloc, path, urlencode(q), frag))
        links.append(f"<{next_url}>; rel=\"next\"")

    # last
    if total is not None and total > 0:
        last_off = max(0, ((total - 1) // limit) * limit)
        q[offset_param] = str(last_off)
        last_url = urlunsplit((scheme, netloc, path, urlencode(q), frag))
        links.append(f"<{last_url}>; rel=\"last\"")

    return ", ".join(links) if links else None

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL") or os.getenv("VITE_SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("VITE_SUPABASE_ANON_KEY")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_KEY")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
SCRAPE_INTERVAL_SECONDS = 6 * 60 * 60
CHICAGO_TZ = pytz.timezone("America/Chicago")


async def scrape_loop(supabase: Client, stop_evt: asyncio.Event):
    """Background loop to scrape data at regular intervals"""
    try:
        while not stop_evt.is_set():
            await scrape_all_data(supabase)
            try:
                await asyncio.wait_for(stop_evt.wait(), timeout=SCRAPE_INTERVAL_SECONDS)
            except asyncio.TimeoutError:
                pass
    except asyncio.CancelledError:
        print("Scrape loop cancelled")
        raise


async def generate_750am_report(supabase: Client):
    """Generate 7:50 AM report"""
    try:
        print(f"[{datetime.now().isoformat()}] Generating 7:50 AM report...")
        generator = NBAReportGenerator(supabase)
        report = await generator.generate_750am_report()
        await generator.save_report(report, "750am_previous_day")
        print(f"[{datetime.now().isoformat()}] 7:50 AM report completed")
    except Exception as e:
        print(f"Error generating 7:50 AM report: {e}")


async def generate_800am_report(supabase: Client):
    """Generate 8:00 AM report"""
    try:
        print(f"[{datetime.now().isoformat()}] Generating 8:00 AM report...")
        generator = NBAReportGenerator(supabase)
        report = await generator.generate_800am_report()
        await generator.save_report(report, "800am_morning")
        print(f"[{datetime.now().isoformat()}] 8:00 AM report completed")
    except Exception as e:
        print(f"Error generating 8:00 AM report: {e}")


async def generate_1100am_report(supabase: Client):
    """Generate 11:00 AM report"""
    try:
        print(f"[{datetime.now().isoformat()}] Generating 11:00 AM report...")
        generator = NBAReportGenerator(supabase)
        report = await generator.generate_1100am_report()
        await generator.save_report(report, "1100am_gameday")
        print(f"[{datetime.now().isoformat()}] 11:00 AM report completed")
    except Exception as e:
        print(f"Error generating 11:00 AM report: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage app lifecycle - startup and shutdown"""
    # Initialize Supabase client first  
    try:
        config = get_supabase_config()
        
        if not config["available"]:
            raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
            
        # Use SERVICE_ROLE_KEY for backend operations (has elevated privileges)
        service_key = config["service_key"] or config["anon_key"]
        supabase = create_isolated_supabase_client(config["url"], service_key)
        app.state.supabase = supabase
        
        if config["service_key"]:
            print("[OK] Starting application with Supabase (Service Role)")
        else:
            print("[WARNING] Starting application with Supabase (Anon Key - limited permissions)")
        
        # Import scrapers after Supabase client is created to avoid conflicts
        try:
            from scrapers import scrape_all_data as real_scrape_all_data
            from reports import NBAReportGenerator as RealNBAReportGenerator
            
            # Replace mock functions with real implementations
            global scrape_all_data, NBAReportGenerator
            scrape_all_data = real_scrape_all_data
            NBAReportGenerator = RealNBAReportGenerator
            print("[OK] Anti-bot scraping system loaded")
            
        except ImportError as ie:
            print(f"[WARNING] Scrapers not available: {ie}")
        
        # Start data scraping on startup (only if enabled)
        if os.getenv("AUTO_SCRAPE_ON_START", "false").lower() == "true":
            await scrape_all_data(supabase)
        else:
            print("Automatic scraping on startup disabled. Use /api/scrape endpoints to trigger manually.")
            
    except Exception as e:
        print(f"[ERROR] Error initializing Supabase: {e}")
        print("[INFO] Running in development mode without Supabase...")
        app.state.supabase = None

    # Set up scheduler for reports if scheduling is enabled (even without Supabase in dev mode)
    scheduler_enabled = os.getenv("ENABLE_SCHEDULER", "false").lower() == "true"
    
    if scheduler_enabled:
        scheduler = AsyncIOScheduler(timezone=CHICAGO_TZ)

        scheduler.add_job(
            generate_750am_report,
            CronTrigger(hour=7, minute=50, timezone=CHICAGO_TZ),
            args=[app.state.supabase],
            id="report_750am"
        )

        scheduler.add_job(
            generate_800am_report,
            CronTrigger(hour=8, minute=0, timezone=CHICAGO_TZ),
            args=[app.state.supabase],
            id="report_800am"
        )

        scheduler.add_job(
            generate_1100am_report,
            CronTrigger(hour=11, minute=0, timezone=CHICAGO_TZ),
            args=[app.state.supabase],
            id="report_1100am"
        )

        scheduler.start()
        print("[OK] Scheduler enabled and running")

        if app.state.supabase:
            app.state.stop_evt = asyncio.Event()
            task = asyncio.create_task(scrape_loop(app.state.supabase, app.state.stop_evt))
            print("[OK] Background scraping task started")
        else:
            print("[WARNING] Background scraping disabled - no Supabase connection")
            task = None
    else:
        print("[ERROR] Scheduler disabled - set ENABLE_SCHEDULER=true to enable")
        scheduler = None
        task = None

    try:
        yield
    finally:
        print("Shutting down application...")
        if hasattr(app.state, 'stop_evt') and app.state.stop_evt:
            app.state.stop_evt.set()
        if task:
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
        if scheduler:
            scheduler.shutdown(wait=False)


app = FastAPI(title="NBA Analysis API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/odds/find")
async def find_game_odds(
    slug: Optional[str] = None,
    home_abbr: Optional[str] = None,
    away_abbr: Optional[str] = None,
    date: Optional[str] = None,
):
    """Find odds for a single game by team abbreviations and date or slug.
    - slug formats accepted (examples): CHI-LAL-2025-11-05, CHI@LAL-20251105
    - query params: home_abbr, away_abbr, date (YYYY-MM-DD)
    Returns the matched game with bookmakers and a flattened odds list for convenience.
    """
    try:
        # Build abbr -> full name map
        teams = await fetch_nba_teams()
        abbr_to_full = { (t.get("abbreviation") or "").upper(): t.get("full_name") for t in teams }

        ha = (home_abbr or "").upper() or None
        aa = (away_abbr or "").upper() or None
        game_date = date

        # Parse slug if given
        if slug and (not ha or not aa):
            import re
            # Extract tokens; assume first two 2-4 letter upper tokens are abbrs
            tokens = re.split(r"[^A-Za-z0-9]+", slug.upper())
            cand_abbrs = [t for t in tokens if 2 <= len(t) <= 4 and t.isalpha()]
            if len(cand_abbrs) >= 2:
                ha = ha or cand_abbrs[0]
                aa = aa or cand_abbrs[1]
            # Extract date (8 or 10 digits)
            cand_dates = [t for t in tokens if t.isdigit() and len(t) in (8,10)]
            if cand_dates and not game_date:
                d = cand_dates[0]
                if len(d) == 8:
                    game_date = f"{d[0:4]}-{d[4:6]}-{d[6:8]}"
                else:
                    # try yyyy-mm-dd already formatted tokens joined back
                    game_date = "-".join([d[0:4], d[5:7], d[8:10]]) if '-' in slug else d

        if not (ha and aa):
            raise HTTPException(status_code=400, detail="home_abbr and away_abbr (or slug) are required")

        home_full = abbr_to_full.get(ha)
        away_full = abbr_to_full.get(aa)
        if not home_full or not away_full:
            raise HTTPException(status_code=404, detail="Unknown team abbreviation(s)")

        # Use external odds list regardless of DB presence for freshness
        games = await fetch_live_odds()
        match = None
        for g in games:
            if g.get("homeTeam") == home_full and g.get("awayTeam") == away_full:
                if game_date:
                    # Compare date only
                    gdate = (g.get("startTime") or "")[:10]
                    if gdate == game_date:
                        match = g
                        break
                else:
                    match = g
                    break

        if not match:
            # Try reversed home/away
            for g in games:
                if g.get("homeTeam") == away_full and g.get("awayTeam") == home_full:
                    if game_date:
                        gdate = (g.get("startTime") or "")[:10]
                        if gdate == game_date:
                            match = g
                            break
                    else:
                        match = g
                        break

        if not match:
            return {"game": None, "odds": [], "source": "external_odds", "note": "no match"}

        # Build flattened odds like /api/odds/{game_id}
        flat_rows = []
        for bm in match.get("bookmakers", []):
            name = bm.get("name")
            ml = bm.get("moneyline", {})
            if ml.get("home") is not None:
                flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "h2h", "team": match.get("homeTeam"), "price": ml.get("home")})
            if ml.get("away") is not None:
                flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "h2h", "team": match.get("awayTeam"), "price": ml.get("away")})
            sp = bm.get("spread", {})
            if sp:
                line = sp.get("line", 0)
                if sp.get("home") is not None:
                    flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "spread", "team": match.get("homeTeam"), "price": sp.get("home"), "point": line})
                if sp.get("away") is not None:
                    flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "spread", "team": match.get("awayTeam"), "price": sp.get("away"), "point": line})
            tot = bm.get("total", {})
            if tot:
                tline = tot.get("line", 0)
                if tot.get("over") is not None:
                    flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "totals", "outcome_name": "Over", "price": tot.get("over"), "point": tline})
                if tot.get("under") is not None:
                    flat_rows.append({"bookmaker_title": name, "bookmaker_key": name, "market_type": "totals", "outcome_name": "Under", "price": tot.get("under"), "point": tline})

        return {"game": match, "odds": flat_rows, "source": "external_odds"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error finding game odds: {e}")
        raise HTTPException(status_code=500, detail="Failed to find game odds")


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok", "timestamp": datetime.now().isoformat()}


@app.get("/api/teams")
async def get_teams(limit: int = Query(100), offset: int = Query(0)):
    """Get all teams with pagination"""
    try:
        logger.info(f"Getting teams with limit={limit}, offset={offset}")
        supabase = app.state.supabase
        if supabase:
            try:
                logger.info("Executing Supabase query...")
                response = supabase.table("teams").select("*").limit(limit).offset(offset).execute()
                logger.info(f"Supabase response: {len(response.data)} teams")
                if response.data:
                    return {"teams": response.data}
                # Fallback to external API if database has no teams
                logger.info("No teams in database, falling back to external API (balldontlie)")
                external_teams = await fetch_nba_teams()
                return {"teams": external_teams, "source": "balldontlie"}
            except Exception as e:
                logger.error(f"Supabase query error: {e}")
                # Fallback to external API on DB error
                external_teams = await fetch_nba_teams()
                return {"teams": external_teams, "source": "balldontlie", "error": f"Database error: {str(e)}"}
        else:
            # Use external API when Supabase is not configured
            external_teams = await fetch_nba_teams()
            return {"teams": external_teams, "source": "balldontlie"}
    except Exception as e:
        return {"error": str(e)}, 500


@app.post("/api/scrape/teams")
async def trigger_teams_scrape():
    """Manually trigger scraping and saving NBA teams"""
    try:
        from scrapers import get_teams_data, save_teams
        supabase = app.state.supabase
        if not supabase:
            raise HTTPException(status_code=503, detail="Supabase not configured")

        teams = await get_teams_data()
        if not teams:
            return {"success": False, "message": "No teams scraped"}

        await save_teams(supabase, teams)
        return {
            "success": True,
            "message": f"Saved {len(teams)} teams",
            "count": len(teams),
            "timestamp": datetime.now().isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error scraping teams: {e}")
        raise HTTPException(status_code=500, detail="Failed to scrape teams")


@app.get("/api/teams/rosters")
async def get_all_team_rosters(active: bool = True):
    """Return all teams with their players (optionally only active)."""
    try:
        supabase = app.state.supabase
        if not supabase:
            raise HTTPException(status_code=503, detail="Supabase not configured")

        teams_resp = await anyio.to_thread.run_sync(
            lambda: supabase.table("teams").select("*").order("abbreviation").execute()
        )

        players_query = supabase.table("players").select(
            """
            *,
            teams!players_team_id_fkey (
                abbreviation,
                full_name,
                city,
                name
            )
            """
        )
        if active is not None:
            players_query = players_query.eq("is_active", active)
        players_query = players_query.order("team_abbreviation").order("jersey_number")

        players_resp = await anyio.to_thread.run_sync(lambda: players_query.execute())

        # Group players by team abbreviation
        roster_map = {}
        for p in players_resp.data or []:
            abbr = p.get("team_abbreviation")
            roster_map.setdefault(abbr, []).append(p)

        # Attach players to team objects
        results = []
        for t in teams_resp.data or []:
            abbr = t.get("abbreviation")
            results.append({
                **t,
                "players": roster_map.get(abbr, []),
                "players_count": len(roster_map.get(abbr, [])),
            })

        return {
            "teams": results,
            "teams_count": len(results),
            "players_total": len(players_resp.data or []),
            "timestamp": datetime.now().isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching team rosters: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch team rosters")


@app.get("/api/games/today")
async def get_today_games():
    """Get today's games"""
    try:
        supabase = app.state.supabase
        today = datetime.now().date()
        tomorrow = today + timedelta(days=1)

        if supabase:
            response = await anyio.to_thread.run_sync(
                lambda: supabase.table("games")
                .select("*")
                .gte("commence_time", today.isoformat())
                .lt("commence_time", tomorrow.isoformat())
                .execute()
            )
            if response.data:
                return {"games": response.data}

        # Fallback to external API when no DB or no games found
        # Try today first
        start_str = today.isoformat()
        end_str = today.isoformat()
        external_games = await fetch_nba_games(start_date=start_str, end_date=end_str)
        if external_games:
            return {"games": external_games, "source": "balldontlie"}

        # If no games today, fetch upcoming games for next 3 days
        end_upcoming = (today + timedelta(days=3)).isoformat()
        upcoming_games = await fetch_nba_games(start_date=today.isoformat(), end_date=end_upcoming)
        if upcoming_games:
            # Optionally, filter to games commencing after now
            now_iso = datetime.now().isoformat()
            upcoming_sorted = [g for g in upcoming_games if g.get("commence_time", now_iso) >= now_iso]
            upcoming_sorted.sort(key=lambda g: g.get("commence_time", ""))
            return {"games": upcoming_sorted, "source": "balldontlie", "note": "upcoming"}

        # Final fallback: no games from external API
        return {"games": [], "source": "balldontlie", "note": "none_found"}
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/api/odds/{game_id}")
async def get_game_odds(game_id: str):
    """Get odds for a specific game"""
    try:
        supabase = app.state.supabase
        if supabase:
            response = await anyio.to_thread.run_sync(
                lambda: supabase.table("odds").select("*").eq("game_id", game_id).execute()
            )
            return {"odds": response.data}

        # External fallback using live odds list
        games = await fetch_live_odds()
        match = next((g for g in games if g.get("gameId") == game_id), None)
        if not match:
            return {"odds": [], "source": "external_odds", "note": "game not found"}

        flat_rows = []
        for bm in match.get("bookmakers", []):
            name = bm.get("name")
            # Moneyline
            ml = bm.get("moneyline", {})
            if ml.get("home") is not None:
                flat_rows.append({
                    "bookmaker_title": name,
                    "bookmaker_key": name,
                    "market_type": "h2h",
                    "team": match.get("homeTeam"),
                    "price": ml.get("home"),
                })
            if ml.get("away") is not None:
                flat_rows.append({
                    "bookmaker_title": name,
                    "bookmaker_key": name,
                    "market_type": "h2h",
                    "team": match.get("awayTeam"),
                    "price": ml.get("away"),
                })
            # Spread
            sp = bm.get("spread", {})
            if sp:
                line = sp.get("line", 0)
                if sp.get("home") is not None:
                    flat_rows.append({
                        "bookmaker_title": name,
                        "bookmaker_key": name,
                        "market_type": "spread",
                        "team": match.get("homeTeam"),
                        "price": sp.get("home"),
                        "point": line,
                    })
                if sp.get("away") is not None:
                    flat_rows.append({
                        "bookmaker_title": name,
                        "bookmaker_key": name,
                        "market_type": "spread",
                        "team": match.get("awayTeam"),
                        "price": sp.get("away"),
                        "point": line,
                    })
            # Totals
            tot = bm.get("total", {})
            if tot:
                tline = tot.get("line", 0)
                if tot.get("over") is not None:
                    flat_rows.append({
                        "bookmaker_title": name,
                        "bookmaker_key": name,
                        "market_type": "totals",
                        "outcome_name": "Over",
                        "price": tot.get("over"),
                        "point": tline,
                    })
                if tot.get("under") is not None:
                    flat_rows.append({
                        "bookmaker_title": name,
                        "bookmaker_key": name,
                        "market_type": "totals",
                        "outcome_name": "Under",
                        "price": tot.get("under"),
                        "point": tline,
                    })

        return {"odds": flat_rows, "source": "external_odds"}
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/api/live-odds")
async def get_live_odds():
    """Get real-time odds from multiple bookmakers for today's games"""
    try:
        supabase = app.state.supabase
        if not supabase:
            # Use external odds provider when Supabase is not configured
            ext_games = await fetch_live_odds()
            return {"games": ext_games, "count": len(ext_games), "timestamp": datetime.now().isoformat(), "source": "external_odds"}

        # Get today's games first
        today = datetime.now().date()
        tomorrow = today + timedelta(days=1)

        games_response = await anyio.to_thread.run_sync(
            lambda: supabase.table("games")
            .select("*")
            .gte("commence_time", today.isoformat())
            .lt("commence_time", tomorrow.isoformat())
            .execute()
        )

        if not games_response.data:
            # Fallback to external odds if no games are found in DB
            ext_games = await fetch_live_odds()
            return {"games": ext_games, "count": len(ext_games), "timestamp": datetime.now().isoformat(), "source": "external_odds"}

        # Get odds for each game
        games_with_odds = []
        for game in games_response.data:
            odds_response = await anyio.to_thread.run_sync(
                lambda g=game: supabase.table("odds")
                .select("*")
                .eq("game_id", g["id"])
                .execute()
            )
            
            # Process odds by bookmaker
            bookmakers_data = {}
            for odd in odds_response.data or []:
                bookmaker = odd.get("bookmaker_key")
                if bookmaker not in bookmakers_data:
                    bookmakers_data[bookmaker] = {
                        "name": odd.get("bookmaker_title", bookmaker),
                        "moneyline": {},
                        "spread": {},
                        "total": {}
                    }
                
                market = odd.get("market_type")
                if market == "h2h":
                    if odd.get("team") == game["home_team"]:
                        bookmakers_data[bookmaker]["moneyline"]["home"] = odd.get("price")
                    else:
                        bookmakers_data[bookmaker]["moneyline"]["away"] = odd.get("price")
                elif market == "spread":
                    if odd.get("team") == game["home_team"]:
                        bookmakers_data[bookmaker]["spread"]["home"] = odd.get("price")
                        bookmakers_data[bookmaker]["spread"]["line"] = odd.get("point", 0)
                    else:
                        bookmakers_data[bookmaker]["spread"]["away"] = odd.get("price")
                elif market == "totals":
                    if odd.get("outcome_name") == "Over":
                        bookmakers_data[bookmaker]["total"]["over"] = odd.get("price")
                        bookmakers_data[bookmaker]["total"]["line"] = odd.get("point", 0)
                    else:
                        bookmakers_data[bookmaker]["total"]["under"] = odd.get("price")

            games_with_odds.append({
                "gameId": game["id"],
                "homeTeam": game["home_team"],
                "awayTeam": game["away_team"],
                "startTime": game["commence_time"],
                "bookmakers": list(bookmakers_data.values()),
                "movements": []  # TODO: Implement line movement tracking
            })

        return {
            "games": games_with_odds,
            "count": len(games_with_odds),
            "timestamp": datetime.now().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching live odds: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch live odds")


@app.get("/api/players/{player_id}/stats")
async def get_player_stats(player_id: str, season: str = "2024-25"):
    """Get detailed statistics for a specific player"""
    try:
        supabase = app.state.supabase
        if not supabase:
            # External stats from balldontlie season averages
            stats = await fetch_player_stats(player_id)
            return {
                "player": {"id": player_id},
                "stats": stats or {},
                "season": season,
                "last_updated": datetime.now().isoformat()
            }

        # Get player info
        player_response = await anyio.to_thread.run_sync(
            lambda: supabase.table("players")
            .select("""
                *,
                teams!players_team_id_fkey (
                    abbreviation,
                    full_name,
                    city,
                    name
                )
            """)
            .eq("id", player_id)
            .execute()
        )

        if not player_response.data:
            raise HTTPException(status_code=404, detail=f"Player with ID '{player_id}' not found")

        player = player_response.data[0]
        
        # TODO: Replace mock stats with real aggregated stats when available in DB
        import random
        mock_stats = {
            "ppg": round(random.uniform(8.0, 32.0), 1),
            "rpg": round(random.uniform(2.0, 14.0), 1),
            "apg": round(random.uniform(1.5, 11.0), 1),
            "fg_percentage": round(random.uniform(0.35, 0.65), 3),
            "three_point_percentage": round(random.uniform(0.25, 0.45), 3),
            "ft_percentage": round(random.uniform(0.65, 0.95), 3),
            "steals": round(random.uniform(0.3, 2.5), 1),
            "blocks": round(random.uniform(0.1, 3.0), 1),
            "turnovers": round(random.uniform(1.0, 4.5), 1),
            "minutes_per_game": round(random.uniform(15.0, 40.0), 1),
            "games_played": random.randint(45, 82),
            "field_goals_made": round(random.uniform(3.0, 12.0), 1),
            "field_goals_attempted": round(random.uniform(7.0, 25.0), 1),
            "three_pointers_made": round(random.uniform(0.5, 4.5), 1),
            "three_pointers_attempted": round(random.uniform(1.5, 12.0), 1),
            "free_throws_made": round(random.uniform(1.0, 8.0), 1),
            "free_throws_attempted": round(random.uniform(1.5, 10.0), 1)
        }

        return {
            "player": player,
            "stats": mock_stats,
            "season": season,
            "last_updated": datetime.now().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching player stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch player stats")


@app.get("/api/teams/{team_abbrev}/stats")
async def get_team_stats(team_abbrev: str, season: str = "2024-25"):
    """Get comprehensive team statistics and analysis"""
    try:
        supabase = app.state.supabase
        if not supabase:
            # Build real team stats from recent external games
            teams = await fetch_nba_teams()
            team = next((t for t in teams if (t.get("abbreviation") or "").upper() == team_abbrev.upper()), None)
            if not team:
                raise HTTPException(status_code=404, detail=f"Team '{team_abbrev}' not found")

            # Fetch last 60 days games and compute last 10
            end_date = datetime.now().date()
            start_date = end_date - timedelta(days=60)
            games = await fetch_nba_games(start_date=start_date.isoformat(), end_date=end_date.isoformat(), team_id=str(team.get("id")))
            games = [g for g in games if g.get("home_team_score") is not None and g.get("visitor_team_score") is not None]
            games.sort(key=lambda g: g.get("commence_time", ""), reverse=True)
            last10 = games[:10]

            wins = 0
            losses = 0
            pts = 0
            opp_pts = 0
            abbr = team_abbrev.upper()
            for g in last10:
                is_home = (g.get("home_team_abbreviation") or "") == abbr
                home = g.get("home_team_score") or 0
                away = g.get("visitor_team_score") or 0
                team_pts = home if is_home else away
                opp = away if is_home else home
                pts += team_pts
                opp_pts += opp
                if team_pts > opp:
                    wins += 1
                else:
                    losses += 1

            cnt = max(1, len(last10))
            ppg = round(pts / cnt, 1)
            papg = round(opp_pts / cnt, 1)

            team_stats = {
                **team,
                "conference": team.get("conference"),
                "division": team.get("division"),
                "season_stats": {
                    "wins": wins,
                    "losses": losses,
                    "win_percentage": round(wins / (wins + losses), 3) if (wins + losses) else 0,
                    "points_per_game": ppg,
                    "points_allowed": papg,
                    "offensive_rating": ppg,
                    "defensive_rating": papg,
                    "net_rating": round(ppg - papg, 1)
                },
                "recent_form": {
                    "last_10": f"{wins}-{losses}"
                },
                "betting_stats": {
                    "avg_total": round(((pts + opp_pts) / cnt), 1)
                },
                "last_updated": datetime.now().isoformat()
            }
            return team_stats

        # Get team info
        team_response = await anyio.to_thread.run_sync(
            lambda: supabase.table("teams")
            .select("*")
            .eq("abbreviation", team_abbrev.upper())
            .execute()
        )

        if not team_response.data:
            raise HTTPException(status_code=404, detail=f"Team '{team_abbrev}' not found")

        team = team_response.data[0]
        
    # Mock team stats - in production, these would come from scraping/DB metrics
        import random
        
        # Determine conference and division
        conferences = {
            'Eastern': ['ATL', 'BOS', 'BKN', 'CHA', 'CHI', 'CLE', 'DET', 'IND', 'MIA', 'MIL', 'NYK', 'ORL', 'PHI', 'TOR', 'WAS'],
            'Western': ['DAL', 'DEN', 'GSW', 'HOU', 'LAC', 'LAL', 'MEM', 'MIN', 'NOP', 'OKC', 'PHX', 'POR', 'SAC', 'SAS', 'UTA']
        }
        
        divisions = {
            'Atlantic': ['BOS', 'BKN', 'NYK', 'PHI', 'TOR'],
            'Central': ['CHI', 'CLE', 'DET', 'IND', 'MIL'],
            'Southeast': ['ATL', 'CHA', 'MIA', 'ORL', 'WAS'],
            'Northwest': ['DEN', 'MIN', 'OKC', 'POR', 'UTA'],
            'Pacific': ['GSW', 'LAC', 'LAL', 'PHX', 'SAC'],
            'Southwest': ['DAL', 'HOU', 'MEM', 'NOP', 'SAS']
        }
        
        abbr = team_abbrev.upper()
        conference = 'Eastern' if abbr in conferences['Eastern'] else 'Western'
        division = next((div for div, teams in divisions.items() if abbr in teams), 'Unknown')
        
        wins = random.randint(15, 55)
        losses = random.randint(10, 50)
        
        team_stats = {
            **team,
            "conference": conference,
            "division": division,
            "season_stats": {
                "wins": wins,
                "losses": losses,
                "win_percentage": round(wins / (wins + losses), 3),
                "points_per_game": round(random.uniform(105.0, 125.0), 1),
                "points_allowed": round(random.uniform(105.0, 125.0), 1),
                "offensive_rating": round(random.uniform(105.0, 125.0), 1),
                "defensive_rating": round(random.uniform(105.0, 125.0), 1),
                "net_rating": round(random.uniform(-15.0, 15.0), 1),
                "field_goal_percentage": round(random.uniform(0.42, 0.52), 3),
                "three_point_percentage": round(random.uniform(0.32, 0.42), 3),
                "free_throw_percentage": round(random.uniform(0.72, 0.85), 3),
                "rebounds_per_game": round(random.uniform(40.0, 50.0), 1),
                "assists_per_game": round(random.uniform(20.0, 30.0), 1),
                "steals_per_game": round(random.uniform(6.0, 10.0), 1),
                "blocks_per_game": round(random.uniform(3.0, 7.0), 1),
                "turnovers_per_game": round(random.uniform(12.0, 18.0), 1)
            },
            "recent_form": {
                "last_10": f"{random.randint(3, 8)}-{random.randint(2, 7)}",
                "last_5": f"{random.randint(1, 5)}-{random.randint(0, 4)}",
                "home_record": f"{random.randint(8, 30)}-{random.randint(5, 25)}",
                "away_record": f"{random.randint(5, 25)}-{random.randint(10, 30)}",
                "vs_conference": f"{random.randint(10, 30)}-{random.randint(10, 30)}"
            },
            "betting_stats": {
                "ats_record": f"{random.randint(25, 40)}-{random.randint(20, 35)}",
                "ats_percentage": round(random.uniform(0.45, 0.65), 3),
                "over_under": f"{random.randint(25, 40)}-{random.randint(20, 35)}",
                "ou_percentage": round(random.uniform(0.45, 0.65), 3),
                "avg_total": round(random.uniform(210.0, 235.0), 1)
            },
            "strength_rating": random.randint(65, 95),
            "last_updated": datetime.now().isoformat()
        }

        return team_stats
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching team stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch team stats")


# ===========================
# REPLACED: /api/players
# ===========================
@app.get("/api/players")
async def get_all_players(
    request: Request,
    response: Response,
    team: Optional[str] = None,
    position: Optional[str] = None,
    active: Optional[bool] = True,
    limit: Optional[int] = None,
    offset: int = 0,
    order_by: str = "team_abbreviation,jersey_number",
    order_dir: str = "asc,asc",
):
    """Get all players with optional filters, pagination and sorting"""
    try:
        supabase = app.state.supabase
        if supabase:
            query = supabase.table("players").select(
                """
                *,
                teams!players_team_id_fkey (
                    abbreviation,
                    full_name,
                    city,
                    name
                )
                """,
                count="exact",
            )

            if team:
                query = query.eq("team_abbreviation", team.upper())
            if position:
                query = query.ilike("position", f"%{position}%")
            if active is not None:
                query = query.eq("is_active", active)

            # Ordering (whitelist + niezależne kierunki)
            allowed_cols = {"id","name","team_abbreviation","jersey_number","position","height","weight","experience","birth_date","is_active","scraped_at","season_year","created_at","updated_at"}
            for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
                query = query.order(col, desc=desc_flag)

            # Pagination (limit max 500)
            if limit is not None:
                lim = _clamp_limit(limit)
                start = max(0, int(offset))
                end = start + lim - 1
                query = query.range(start, end)
            else:
                lim = None

            db_resp = await anyio.to_thread.run_sync(lambda: query.execute())
            result = {"players": db_resp.data or [], "count": len(db_resp.data or [])}
            total = getattr(db_resp, "count", None)
            if total is not None:
                result["total"] = total
            if lim is not None:
                result["limit"] = lim
                result["offset"] = offset
                link = _build_pagination_links(request, lim, offset, total)
                if link:
                    response.headers["Link"] = link
            return result
        else:
            # Use external API (balldontlie) when Supabase is not configured
            ext_players = await fetch_nba_players()

            # Transform into expected flat structure
            players = [
                {
                    "id": p.get("id"),
                    "name": p.get("name"),
                    "team_abbreviation": p.get("team_abbreviation"),
                    "position": p.get("position"),
                    "jersey_number": p.get("jersey_number"),
                    "is_active": p.get("is_active", True),
                }
                for p in ext_players
            ]

            # Filters
            if team:
                players = [p for p in players if (p.get("team_abbreviation") or "").upper() == team.upper()]
            if position:
                pos = position.upper()
                players = [p for p in players if pos in (p.get("position") or "").upper()]
            if active is not None and active is False:
                players = [p for p in players if not p.get("is_active", True)]

            # Ordering
            allowed_cols = {"id","name","team_abbreviation","jersey_number","position","is_active"}
            for col, desc_flag in reversed(_parse_ordering(order_by, order_dir, allowed_cols)):
                players.sort(key=lambda x: x.get(col), reverse=desc_flag)

            total_count = len(players)

            # Pagination
            lim = None
            if limit is not None:
                lim = _clamp_limit(limit)
                start = max(0, int(offset))
                end = start + lim
                players = players[start:end]

            result = {"players": players, "count": len(players), "total": total_count, "source": "balldontlie"}
            if lim is not None:
                result["limit"] = lim
                result["offset"] = offset
            return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching players: {e}")
        return {"error": str(e)}, 500


@app.get("/api/teams/{team_abbrev}/players")
async def get_team_players(team_abbrev: str, order_by: str = "jersey_number", order_dir: str = "asc"):
    """Get all players for a specific team with ordering"""
    try:
        supabase = app.state.supabase

        if not supabase:
            # External fallback
            ext_players = await fetch_nba_players()
            filtered = [p for p in ext_players if (p.get("team_abbreviation") or "").upper() == team_abbrev.upper()]
            return {"team": team_abbrev.upper(), "players": filtered, "count": len(filtered), "source": "balldontlie"}

        q = supabase.table("players").select(
            """
                *,
                teams!players_team_id_fkey (
                    abbreviation,
                    full_name,
                    city,
                    name
                )
            """
        )
        q = q.eq("team_abbreviation", team_abbrev.upper()).eq("is_active", True)

        allowed_cols = {"jersey_number","name","position","team_abbreviation","created_at","updated_at"}
        parsed = _parse_ordering(order_by, order_dir, allowed_cols)
        if parsed:
            for col, desc_flag in parsed:
                q = q.order(col, desc=desc_flag)
        else:
            q = q.order("jersey_number")

        response = await anyio.to_thread.run_sync(lambda: q.execute())

        if not response.data:
            team_check = await anyio.to_thread.run_sync(
                lambda: supabase.table("teams").select("abbreviation").eq("abbreviation", team_abbrev.upper()).execute()
            )
            if not team_check.data:
                raise HTTPException(status_code=404, detail=f"Team '{team_abbrev}' not found")
            else:
                return {"players": [], "count": 0, "message": f"No active players found for {team_abbrev}"}

        return {"team": team_abbrev.upper(), "players": response.data, "count": len(response.data)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching team players: {e}")
        return {"error": str(e)}, 500


@app.get("/api/players/export")
async def export_players(
    format: str = "csv",
    team: Optional[str] = None,
    position: Optional[str] = None,
    active: Optional[bool] = True,
    order_by: str = "team_abbreviation,jersey_number",
    order_dir: str = "asc,asc",
    limit: Optional[int] = None,
    offset: int = 0,
):
    """Export players as CSV or Excel (xlsx) with optional filters."""
    try:
        supabase = app.state.supabase
        if not supabase:
            # Export from external API when Supabase is not configured
            ext_players = await fetch_nba_players()

            # Apply basic filtering on external data
            rows = ext_players
            if team:
                rows = [r for r in rows if (r.get("team_abbreviation") or "").upper() == team.upper()]
            if position:
                pos = position.upper()
                rows = [r for r in rows if pos in (r.get("position") or "").upper()]
            if active is not None:
                rows = [r for r in rows if bool(r.get("is_active", True)) == bool(active)]

            # Ordering
            allowed_cols = {"id","name","team_abbreviation","jersey_number","position","is_active"}
            for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
                rows.sort(key=lambda x: x.get(col), reverse=desc_flag)

            # Produce CSV or XLSX
            if format.lower() in ("csv",):
                buf = io.StringIO()
                all_keys = set()
                for fr in rows:
                    all_keys.update(fr.keys())
                fieldnames = sorted(all_keys)
                writer = csv.DictWriter(buf, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(rows)
                buf.seek(0)
                headers = {"Content-Disposition": "attachment; filename=players.csv"}
                return StreamingResponse(iter([buf.getvalue()]), media_type="text/csv", headers=headers)
            elif format.lower() in ("xlsx", "excel"):
                df = pd.DataFrame(rows)
                xbuf = io.BytesIO()
                with pd.ExcelWriter(xbuf, engine="xlsxwriter") as writer:
                    df.to_excel(writer, index=False, sheet_name="players")
                xbuf.seek(0)
                headers = {"Content-Disposition": "attachment; filename=players.xlsx"}
                return StreamingResponse(xbuf, media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", headers=headers)
            else:
                raise HTTPException(status_code=400, detail="Unsupported format. Use csv or xlsx")

        query = supabase.table("players").select(
            """
            *,
            teams!players_team_id_fkey (
                abbreviation,
                full_name,
                city,
                name
            )
            """,
            count="exact",
        )
        if team:
            query = query.eq("team_abbreviation", team.upper())
        if position:
            query = query.ilike("position", f"%{position}%")
        if active is not None:
            query = query.eq("is_active", active)

        # Ordering (whitelist + independent directions)
        allowed_cols = {"id","name","team_abbreviation","jersey_number","position","height","weight","experience","birth_date","is_active","scraped_at","season_year","created_at","updated_at"}
        for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
            query = query.order(col, desc=desc_flag)

        if limit is not None:
            lim = _clamp_limit(limit)
            start = max(0, int(offset))
            end = start + lim - 1
            query = query.range(start, end)
        else:
            lim = None
        response = await anyio.to_thread.run_sync(lambda: query.execute())
        rows = response.data or []

        # Flatten nested team info for export
        flat_rows = []
        for r in rows:
            flat = dict(r)
            teams_info = flat.pop("teams", None)
            if isinstance(teams_info, dict):
                flat["team_full_name"] = teams_info.get("full_name")
                flat["team_city"] = teams_info.get("city")
                flat["team_name"] = teams_info.get("name")
            flat_rows.append(flat)

        if format.lower() in ("csv",):
            buf = io.StringIO()
            # Determine fieldnames
            all_keys = set()
            for fr in flat_rows:
                all_keys.update(fr.keys())
            fieldnames = sorted(all_keys)
            writer = csv.DictWriter(buf, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(flat_rows)
            buf.seek(0)
            headers = {"Content-Disposition": "attachment; filename=players.csv"}
            return StreamingResponse(iter([buf.getvalue()]), media_type="text/csv", headers=headers)
        elif format.lower() in ("xlsx", "excel"):
            df = pd.DataFrame(flat_rows)
            xbuf = io.BytesIO()
            with pd.ExcelWriter(xbuf, engine="xlsxwriter") as writer:
                df.to_excel(writer, index=False, sheet_name="players")
            xbuf.seek(0)
            headers = {"Content-Disposition": "attachment; filename=players.xlsx"}
            return StreamingResponse(xbuf, media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", headers=headers)
        else:
            raise HTTPException(status_code=400, detail="Unsupported format. Use csv or xlsx")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting players: {e}")
        raise HTTPException(status_code=500, detail="Failed to export players")


@app.get("/api/players/{player_id}")
async def get_player_details(player_id: str):
    """Get detailed information for a specific player"""
    try:
        supabase = app.state.supabase
        if not supabase:
            # External fallback
            player = await fetch_player_by_id(player_id)
            if not player:
                raise HTTPException(status_code=404, detail=f"Player with ID '{player_id}' not found")
            return {"player": player}

        response = await anyio.to_thread.run_sync(
            lambda: supabase.table("players")
            .select("""
                *,
                teams!players_team_id_fkey (
                    abbreviation,
                    full_name,
                    city,
                    name
                )
            """)
            .eq("id", player_id)
            .execute()
        )
        
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Player with ID '{player_id}' not found")
            
        return {"player": response.data[0]}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching player details: {e}")
        return {"error": str(e)}, 500


@app.get("/api/players/search/{name}")
async def search_players_by_name(
    request: Request,
    response: Response,
    name: str,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "name",
    order_dir: str = "asc",
):
    """Search players by name with pagination and ordering"""
    try:
        supabase = app.state.supabase
        if not supabase:
            # External search fallback
            players = await fetch_nba_players(search=name)
            # Ordering whitelist
            allowed_cols = {"name","jersey_number","team_abbreviation","position"}
            for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
                players.sort(key=lambda x: x.get(col), reverse=desc_flag)

            # Pagination
            lim = _clamp_limit(limit, default=50)
            start = max(0, int(offset))
            end = start + lim
            page = players[start:end]

            return {
                "query": name,
                "players": page,
                "count": len(page),
                "total": len(players),
                "limit": lim,
                "offset": offset,
                "source": "balldontlie"
            }

        q = supabase.table("players").select(
            """
            *,
            teams!players_team_id_fkey (
                abbreviation,
                full_name,
                city,
                name
            )
            """,
            count="exact",
        )
        q = q.ilike("name", f"%{name}%").eq("is_active", True)

        allowed_cols = {"name","jersey_number","team_abbreviation","position","created_at","updated_at"}
        for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
            q = q.order(col, desc=desc_flag)

        lim = _clamp_limit(limit, default=50)
        start = max(0, int(offset))
        end = start + lim - 1
        q = q.range(start, end)

        db_resp = await anyio.to_thread.run_sync(lambda: q.execute())
        total = getattr(db_resp, "count", None)
        link = _build_pagination_links(request, lim, offset, total)
        if link:
            response.headers["Link"] = link

        return {
            "query": name,
            "players": db_resp.data or [],
            "count": len(db_resp.data or []),
            "total": total,
            "limit": lim,
            "offset": offset,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error searching players: {e}")
        raise HTTPException(status_code=500, detail="Failed to search players")


@app.post("/api/scrape/rosters")
async def trigger_roster_scrape(season: str = "2025"):
    """Manually trigger roster scraping for all teams"""
    try:
        from scrapers import scrape_all_team_rosters
        
        supabase = app.state.supabase
        
        # Run roster scraping in background
        asyncio.create_task(scrape_all_team_rosters(supabase, season))
        
        return {
            "message": f"Roster scraping initiated for season {season}",
            "timestamp": datetime.now().isoformat(),
            "status": "in_progress"
        }
    except Exception as e:
        logger.error(f"Error triggering roster scrape: {e}")
        raise HTTPException(status_code=500, detail="Failed to trigger roster scraping")


@app.get("/api/status")
async def get_status():
    """Get application status"""
    return {
        "status": "running",
        "scrape_interval_hours": SCRAPE_INTERVAL_SECONDS / 3600,
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/api/reports/750am")
async def get_750am_report():
    """Get 7:50 AM report (previous day analysis)"""
    try:
        # Build a minimal real report using external games
        today = datetime.now().date()
        yesterday = (today - timedelta(days=1)).isoformat()
        games = await fetch_nba_games(start_date=yesterday, end_date=yesterday)
        # Create simple 'results vs line' using median total as proxy for OU
        totals = [(g.get('home_team_score', 0) or 0) + (g.get('visitor_team_score', 0) or 0) for g in games]
        median_total = sorted(totals)[len(totals)//2] if totals else 0
        results_vs_line = []
        for g in games[:10]:
            home = g.get('home_team')
            away = g.get('away_team')
            hs = g.get('home_team_score', 0) or 0
            as_ = g.get('visitor_team_score', 0) or 0
            winner = home if hs >= as_ else away
            ou = 'OVER' if (hs + as_) > median_total else 'UNDER'
            results_vs_line.append({
                'team': f"{home} vs {away}",
                'result': 'W' if winner == home else 'L',
                'ats': 'PUSH',
                'ou': ou
            })
        bulls_games = [g for g in games if 'Bulls' in (g.get('home_team','') + g.get('away_team',''))]
        report = {
            "report_type": "750am_previous_day",
            "timestamp": datetime.now().isoformat(),
            "gamesAnalyzed": len(games),
            "resultsVsLine": results_vs_line,
            "topTrends": [
                "Favorites ATS: n/a (no line data)",
                "O/U proxy uses median total"
            ],
            "bullsAnalysis": {
                "lastGame": (f"{bulls_games[0].get('home_team')} {bulls_games[0].get('home_team_score', 0)} - "
                              f"{bulls_games[0].get('away_team')} {bulls_games[0].get('visitor_team_score', 0)}") if bulls_games else "No game",
                "keyPlayers": []
            },
            "source": "balldontlie"
        }
        return report
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/api/reports/800am")
async def get_800am_report():
    """Get 8:00 AM report (morning summary)"""
    try:
        today = datetime.now().date()
        yesterday = (today - timedelta(days=1)).isoformat()
        games = await fetch_nba_games(start_date=yesterday, end_date=yesterday)
        avg_total = round(sum(((g.get('home_team_score',0) or 0) + (g.get('visitor_team_score',0) or 0)) for g in games) / max(1, len(games)), 1) if games else 0
        report = {
            "report_type": "800am_morning",
            "timestamp": datetime.now().isoformat(),
            "yesterdayResults": [
                f"{g.get('home_team')} {g.get('home_team_score',0)} - {g.get('away_team')} {g.get('visitor_team_score',0)}"
                for g in games[:10]
            ],
            "trends7Day": {
                "offRtg": "OffRtg: N/A",
                "defRtg": "DefRtg: N/A",
                "avgTotal": f"Avg Total: {avg_total}"
            },
            "source": "balldontlie"
        }
        return report
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/api/reports/1100am")
async def get_1100am_report():
    """Get 11:00 AM report (game-day scouting)"""
    try:
        # Minimal placeholder marking as generating until 11:00 local time
        now = datetime.now(CHICAGO_TZ)
        status = "generating" if now.hour < 11 else "ready"
        report = {
            "report_type": "1100am_gameday",
            "timestamp": datetime.now().isoformat(),
            "status": status,
            "source": "balldontlie"
        }
        return report
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/api/bulls-analysis")
async def get_bulls_analysis():
    """Get Bulls-focused analysis and recommendations"""
    try:
        supabase = app.state.supabase
        generator = NBAReportGenerator(supabase)
        analysis = await generator._bulls_gameday_analysis()
        return analysis
    except Exception as e:
        logger.error(f"Error generating Bulls analysis: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate Bulls analysis")


@app.post("/api/scrape/bulls-players")
async def scrape_bulls_players_endpoint():
    """Manually trigger Bulls players scraping with anti-bot protection"""
    try:
        from scrapers import get_bulls_players_data, save_bulls_players
        
        logger.info("Manual Bulls players scraping triggered")
        supabase = app.state.supabase
        
        # Scrape Bulls players using advanced anti-bot protection
        players = await get_bulls_players_data()
        
        if players:
            await save_bulls_players(supabase, players)
            logger.info(f"Successfully scraped and saved {len(players)} Bulls players")
            return {
                "success": True,
                "message": f"Successfully scraped {len(players)} Bulls players",
                "players_count": len(players),
                "timestamp": datetime.now().isoformat()
            }
        else:
            logger.warning("No Bulls players scraped")
            return {
                "success": False,
                "message": "No Bulls players found or scraping failed",
                "players_count": 0,
                "timestamp": datetime.now().isoformat()
            }
            
    except Exception as e:
        logger.error(f"Error scraping Bulls players: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to scrape Bulls players: {str(e)}")


@app.get("/api/betting-recommendations")
async def get_betting_recommendations():
    """Get current betting recommendations"""
    try:
        # Derive simple recommendations from live odds (real source)
        games = await fetch_live_odds()
        recommendations = []
        value_bets = []

        for g in games[:5]:  # limit
            # pick best home ML and best away ML
            best_home = None
            best_away = None
            for bm in g.get("bookmakers", []):
                h = bm.get("moneyline", {}).get("home")
                a = bm.get("moneyline", {}).get("away")
                if isinstance(h, (int, float)):
                    if best_home is None or h > best_home:
                        best_home = h
                if isinstance(a, (int, float)):
                    if best_away is None or a > best_away:
                        best_away = a
            if best_home is None or best_away is None:
                continue

            # Choose side with better payout (higher positive or less negative)
            chosen_side = "home" if (best_home >= best_away) else "away"
            chosen_team = g["homeTeam"] if chosen_side == "home" else g["awayTeam"]
            chosen_odds = best_home if chosen_side == "home" else best_away

            recommendations.append({
                "id": f"rec-{g.get('gameId')}",
                "type": "single",
                "category": "value",
                "title": f"{chosen_team} Moneyline",
                "legs": [{
                    "game": f"{g.get('homeTeam')} vs {g.get('awayTeam')}",
                    "bet": f"{chosen_team} ML",
                    "odds": chosen_odds,
                    "confidence": 60
                }],
                "totalOdds": chosen_odds,
                "stake": 10,
                "potentialPayout": 0,
                "risk": "medium",
                "reasoning": "Selected best available moneyline across books.",
                "kelly": 0
            })

            value_bets.append({
                "game": f"{g.get('homeTeam')} vs {g.get('awayTeam')}",
                "bet": f"{chosen_team} ML",
                "bookmakerOdds": chosen_odds,
                "fairOdds": chosen_odds,  # no model; treat as baseline
                "edge": 0,
                "confidence": 60,
                "maxStake": 0
            })

        return {"recommendations": recommendations, "valueBets": value_bets, "count": len(recommendations), "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"Error generating betting recommendations: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate betting recommendations")


@app.get("/api/arbitrage-opportunities")
async def get_arbitrage_opportunities():
    """Find arbitrage betting opportunities"""
    try:
        supabase = app.state.supabase
        generator = NBAReportGenerator(supabase)
        # Mock odds data - replace with real API integration
        odds_data = []
        opportunities = await generator.identify_arbitrage_opportunities(odds_data)
        return {"opportunities": opportunities, "count": len(opportunities)}
    except Exception as e:
        logger.error(f"Error finding arbitrage opportunities: {e}")
        raise HTTPException(status_code=500, detail="Failed to find arbitrage opportunities")


@app.post("/api/betting-slip")
async def generate_betting_slip(bets: List[dict], total_stake: float = 100):
    """Generate professional betting slip with Kelly criterion sizing"""
    try:
        supabase = app.state.supabase
        generator = NBAReportGenerator(supabase)
        formatted_slip = generator.format_betting_slip(bets, total_stake)
        return formatted_slip
    except Exception as e:
        logger.error(f"Error generating betting slip: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate betting slip")


@app.get("/api/kelly-calculator")
async def calculate_kelly(estimated_prob: float, decimal_odds: float):
    """Calculate Kelly Criterion bet sizing"""
    try:
        supabase = app.state.supabase
        generator = NBAReportGenerator(supabase)
        kelly_fraction = generator.calculate_kelly_criterion(estimated_prob, decimal_odds)
        return {
            "kelly_fraction": kelly_fraction,
            "percentage": kelly_fraction * 100,
            "recommended_stake": f"{kelly_fraction * 100:.2f}% of bankroll"
        }
    except Exception as e:
        logger.error(f"Error calculating Kelly criterion: {e}")
        raise HTTPException(status_code=500, detail="Failed to calculate Kelly criterion")


@app.get("/api/performance-metrics")
async def get_performance_metrics():
    """Get betting performance and ROI metrics"""
    try:
        supabase = app.state.supabase
        generator = NBAReportGenerator(supabase)
        # Mock bet history - replace with real database
        bet_history = []
        metrics = generator.calculate_roi_projection(bet_history)
        return metrics
    except Exception as e:
        logger.error(f"Error calculating performance metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to calculate performance metrics")


@app.get("/api/teams/analysis")
async def get_teams_analysis():
    """Get comprehensive analysis for all NBA teams"""
    try:
        supabase = app.state.supabase
        if supabase:
            teams_response = await anyio.to_thread.run_sync(
                lambda: supabase.table("teams").select("*").order("abbreviation").execute()
            )
            teams = teams_response.data or []
        else:
            teams = await fetch_nba_teams()

        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=45)
        teams_analysis = []
        for team in teams:
            abbr = team.get('abbreviation') if isinstance(team, dict) else team.get('abbreviation')
            team_id = str(team.get('id')) if isinstance(team, dict) else str(team.get('id'))
            try:
                games = await fetch_nba_games(start_date=start_date.isoformat(), end_date=end_date.isoformat(), team_id=team_id)
                games = [g for g in games if g.get("home_team_score") is not None and g.get("visitor_team_score") is not None]
                games.sort(key=lambda g: g.get("commence_time", ""), reverse=True)
                last10 = games[:10]
                wins = 0
                losses = 0
                pts = 0
                opp_pts = 0
                for g in last10:
                    is_home = (g.get("home_team_abbreviation") or "") == abbr
                    home = g.get("home_team_score") or 0
                    away = g.get("visitor_team_score") or 0
                    team_pts = home if is_home else away
                    opp = away if is_home else home
                    pts += team_pts
                    opp_pts += opp
                    if team_pts > opp:
                        wins += 1
                    else:
                        losses += 1
                cnt = max(1, len(last10))
                ppg = round(pts / cnt, 1)
                papg = round(opp_pts / cnt, 1)
                teams_analysis.append({
                    **team,
                    'conference': team.get('conference'),
                    'division': team.get('division'),
                    'season_stats': {
                        'wins': wins,
                        'losses': losses,
                        'win_percentage': round(wins / (wins + losses), 3) if (wins + losses) else 0,
                        'points_per_game': ppg,
                        'points_allowed': papg,
                        'net_rating': round(ppg - papg, 1)
                    },
                    'recent_form': {
                        'last_10': f"{wins}-{losses}"
                    },
                    'betting_stats': {
                        'avg_total': round(((pts + opp_pts) / cnt), 1)
                    },
                    'last_updated': datetime.now().isoformat()
                })
            except Exception:
                continue

        return {
            'teams': teams_analysis,
            'count': len(teams_analysis),
            'conferences': {
                'Eastern': [t for t in teams_analysis if t.get('conference') == 'Eastern'],
                'Western': [t for t in teams_analysis if t.get('conference') == 'Western']
            }
        }
        
    except Exception as e:
        logger.error(f"Error fetching teams analysis: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch teams analysis")


@app.get("/api/teams/{team_abbrev}/analysis")
async def get_team_analysis(team_abbrev: str):
    """Get detailed analysis for a specific team"""
    try:
        supabase = app.state.supabase
        abbr = team_abbrev.upper()
        if not supabase:
            teams = await fetch_nba_teams()
            team = next((t for t in teams if (t.get('abbreviation') or '').upper() == abbr), None)
            if not team:
                raise HTTPException(status_code=404, detail=f"Team '{abbr}' not found")

            end_date = datetime.now().date()
            start_date = end_date - timedelta(days=45)
            games = await fetch_nba_games(start_date=start_date.isoformat(), end_date=end_date.isoformat(), team_id=str(team.get('id')))
            games = [g for g in games if g.get('home_team_score') is not None and g.get('visitor_team_score') is not None]
            games.sort(key=lambda g: g.get('commence_time', ''), reverse=True)
            recent = []
            wins = 0
            losses = 0
            for g in games[:10]:
                is_home = (g.get('home_team_abbreviation') or '') == abbr
                home = g.get('home_team_score') or 0
                away = g.get('visitor_team_score') or 0
                team_score = home if is_home else away
                opp_score = away if is_home else home
                recent.append({
                    'date': g.get('commence_time', '')[:10],
                    'opponent': g.get('away_team_abbreviation') if is_home else g.get('home_team_abbreviation'),
                    'home': is_home,
                    'team_score': team_score,
                    'opponent_score': opp_score,
                    'result': 'W' if team_score > opp_score else 'L',
                    'margin': abs(team_score - opp_score)
                })
                if team_score > opp_score:
                    wins += 1
                else:
                    losses += 1

            ppg = round(sum((rg['team_score'] for rg in recent), 0) / max(1, len(recent)), 1) if recent else 0
            papg = round(sum((rg['opponent_score'] for rg in recent), 0) / max(1, len(recent)), 1) if recent else 0

            analysis = {
                **team,
                'season_record': {
                    'wins': wins,
                    'losses': losses,
                    'win_percentage': round(wins / (wins + losses), 3) if (wins + losses) else 0
                },
                'advanced_stats': {
                    'offensive_rating': ppg,
                    'defensive_rating': papg,
                    'net_rating': round(ppg - papg, 1)
                },
                'recent_games': recent,
                'form_analysis': {
                    'last_10_games': f"{wins}-{losses}"
                },
                'betting_trends': {
                    'avg_total': round(ppg + papg, 1)
                },
                'last_updated': datetime.now().isoformat()
            }
            return analysis

        # DB path (return team basic info with timestamp)
        team_response = await anyio.to_thread.run_sync(
            lambda: supabase.table('teams').select('*').eq('abbreviation', abbr).single().execute()
        )
        if not team_response.data:
            raise HTTPException(status_code=404, detail=f"Team '{abbr}' not found")
        team = team_response.data
        return {**team, 'last_updated': datetime.now().isoformat()}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching team analysis for {team_abbrev}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch team analysis")


@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and monitoring"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "nba-analytics-backend",
        "version": "1.0.0"
    }


# ===========================
# REPLACED: /api/players/paged
# ===========================
@app.get("/api/players/paged")
async def get_players_paged(
    request: Request,
    response: Response,
    team: Optional[str] = None,
    position: Optional[str] = None,
    active: Optional[bool] = True,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "team_abbreviation,jersey_number",
    order_dir: str = "asc,asc",
):
    """Get players with pagination and sorting"""
    try:
        supabase = app.state.supabase
        if not supabase:
            raise HTTPException(status_code=503, detail="Supabase not configured")

        query = supabase.table("players").select(
            """
            *,
            teams!players_team_id_fkey (
                abbreviation,
                full_name,
                city,
                name
            )
            """,
            count="exact",
        )

        if team:
            query = query.eq("team_abbreviation", team.upper())
        if position:
            query = query.ilike("position", f"%{position}%")
        if active is not None:
            query = query.eq("is_active", active)

        # Ordering (whitelist + niezależne kierunki)
        allowed_cols = {"id","name","team_abbreviation","jersey_number","position","height","weight","experience","birth_date","is_active","scraped_at","season_year","created_at","updated_at"}
        for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_cols):
            query = query.order(col, desc=desc_flag)

        # Pagination
        lim = _clamp_limit(limit, default=50)
        start = max(0, int(offset))
        end = start + lim - 1
        query = query.range(start, end)

        db_resp = await anyio.to_thread.run_sync(lambda: query.execute())
        total = getattr(db_resp, "count", None)

        # Link header
        link = _build_pagination_links(request, lim, offset, total)
        if link:
            response.headers["Link"] = link

        return {
            "players": db_resp.data or [],
            "count": len(db_resp.data or []),
            "total": total,
            "limit": lim,
            "offset": offset,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching paged players: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch players")


# ===========================
# REPLACED: /api/players/list
# ===========================
@app.get("/api/players/list")
async def get_players_list(
    request: Request,
    response: Response,
    team: Optional[str] = None,
    position: Optional[str] = None,
    active: Optional[bool] = True,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "team_abbreviation,jersey_number",
    order_dir: str = "asc,asc",
):
    """Alias for players flat list with pagination"""
    return await get_players_paged(request, response, team=team, position=position, active=active, limit=limit, offset=offset, order_by=order_by, order_dir=order_dir)


# ===========================
# REPLACED: /api/teams/rosters/paged
# ===========================
@app.get("/api/teams/rosters/paged")
async def get_all_team_rosters_paged(
    request: Request,
    response: Response,
    active: bool = True,
    team_limit: int = 30,
    team_offset: int = 0,
    order_by: str = "abbreviation",
    order_dir: str = "asc,asc",
):
    """Return paginated teams with their players (optionally only active players)."""
    try:
        supabase = app.state.supabase
        if not supabase:
            raise HTTPException(status_code=503, detail="Supabase not configured")

        # Teams select + ordering whitelist + paginacja
        t_query = supabase.table("teams").select("*", count="exact")
        allowed_team_cols = {"id","abbreviation","full_name","city","name","created_at","updated_at"}
        for col, desc_flag in _parse_ordering(order_by, order_dir, allowed_team_cols):
            t_query = t_query.order(col, desc=desc_flag)

        t_lim = _clamp_limit(team_limit, default=30)
        t_query = t_query.range(max(0, team_offset), max(0, team_offset) + t_lim - 1)
        teams_resp = await anyio.to_thread.run_sync(lambda: t_query.execute())
        teams = teams_resp.data or []
        teams_total = getattr(teams_resp, "count", None)

        if not teams:
            # Link header nawet dla pustego zestawu
            link = _build_pagination_links(request, t_lim, team_offset, teams_total, limit_param="team_limit", offset_param="team_offset")
            if link:
                response.headers["Link"] = link

            return {
                "teams": [],
                "teams_count": 0,
                "teams_total": teams_total or 0,
                "players_total": 0,
                "team_limit": t_lim,
                "team_offset": team_offset,
                "timestamp": datetime.now().isoformat(),
            }

        abbrs = [t.get("abbreviation") for t in teams if t.get("abbreviation")]

        # Players dla wybranych teamów
        p_query = supabase.table("players").select(
            """
            *,
            teams!players_team_id_fkey (
                abbreviation,
                full_name,
                city,
                name
            )
            """
        )
        if active is not None:
            p_query = p_query.eq("is_active", active)
        p_query = p_query.in_("team_abbreviation", abbrs)
        p_query = p_query.order("team_abbreviation").order("jersey_number")
        players_resp = await anyio.to_thread.run_sync(lambda: p_query.execute())

        roster_map = {}
        for p in players_resp.data or []:
            ab = p.get("team_abbreviation")
            roster_map.setdefault(ab, []).append(p)

        results = []
        for t in teams:
            ab = t.get("abbreviation")
            plist = roster_map.get(ab, [])
            results.append({
                **t,
                "players": plist,
                "players_count": len(plist),
            })

        # Link header
        link = _build_pagination_links(request, t_lim, team_offset, teams_total, limit_param="team_limit", offset_param="team_offset")
        if link:
            response.headers["Link"] = link

        return {
            "teams": results,
            "teams_count": len(results),
            "teams_total": teams_total,
            "players_total": len(players_resp.data or []),
            "team_limit": t_lim,
            "team_offset": team_offset,
            "timestamp": datetime.now().isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching paged team rosters: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch team rosters")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
