import httpx
import os
from bs4 import BeautifulSoup
from supabase import Client
from datetime import datetime
import asyncio
import anyio
import re
import logging
from datetime import datetime as dt

# Import our advanced anti-bot scraper
from anti_bot_scraper import BasketballReferenceScraper, scrape_nba_teams, scrape_bulls_players


def _current_season_year_str(now: dt | None = None) -> str:
    """Return season string like '2024-25' for current date.
    Season assumed to start in August.
    """
    now = now or dt.now()
    year = now.year
    # If month >= 8 (Aug-Dec), season is year-(year+1), else (year-1)-year
    if now.month >= 8:
        start_year = year
        end_year = (year + 1) % 100
    else:
        start_year = year - 1
        end_year = year % 100
    return f"{start_year}-{end_year:02d}"

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def get_teams_data():
    """Scrape NBA teams from Basketball-Reference using anti-bot protection"""
    try:
        logger.info("Starting teams data scraping with anti-bot protection")
        teams = await scrape_nba_teams()
        logger.info(f"Successfully scraped {len(teams)} teams")
        return teams
    except Exception as e:
        logger.error(f"Failed to scrape teams data: {e}")
        return []


async def save_teams(supabase: Client, teams: list):
    """Save teams to Supabase"""
    if not teams:
        return

    for team in teams:
        try:
            await anyio.to_thread.run_sync(
                lambda t=team: supabase.table("teams").upsert(
                    [t], on_conflict="abbreviation"
                ).execute()
            )
        except Exception as e:
            print(f"Error saving team {team.get('abbreviation')}: {e}")


async def get_nba_odds():
    """Fetch NBA odds from The Odds API (normalized)."""
    api_key = os.getenv("ODDS_API_KEY")

    async with httpx.AsyncClient(timeout=5.0) as client:
        # Use odds endpoint to include bookmakers and markets
        url = "https://api.the-odds-api.com/v4/sports/basketball_nba/odds"
        params = {
            "apiKey": api_key or "",
            "regions": "us",
            "markets": "h2h,spreads,totals",
            "oddsFormat": "american",
            "dateFormat": "iso",
        }

        response = await client.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        # Normalize: always return a dict with 'events' key for downstream code
        if isinstance(data, list):
            return {"events": data}
        if isinstance(data, dict):
            # Some providers may already wrap; use common keys
            if "events" in data:
                return data
            for key in ("data", "matches", "games", "response"):
                if isinstance(data.get(key), list):
                    return {"events": data[key]}
        return {"events": []}


async def process_odds_data(supabase: Client, odds_data):
    """Process and save odds data to Supabase. Accepts list or dict."""
    if isinstance(odds_data, list):
        events = odds_data
    elif isinstance(odds_data, dict):
        events = odds_data.get("events", [])
    else:
        events = []

    for event in events:
        try:
            game_id = event.get("id")
            home_team = event.get("home_team")
            away_team = event.get("away_team")
            commence_time = event.get("commence_time")

            game_data = {
                "id": game_id,
                "sport_key": event.get("sport_key"),
                "sport_title": event.get("sport_title"),
                "commence_time": commence_time,
                "home_team": home_team,
                "away_team": away_team,
            }

            await anyio.to_thread.run_sync(
                lambda g=game_data: supabase.table("games").upsert(
                    [g], on_conflict="id"
                ).execute()
            )

            bookmakers = event.get("bookmakers", [])
            for bookmaker in bookmakers:
                odds_records = []
                bookmaker_key = bookmaker.get("key")
                bookmaker_title = bookmaker.get("title")
                last_update = bookmaker.get("last_update")

                for market in bookmaker.get("markets", []):
                    market_key = market.get("key")
                    outcomes = market.get("outcomes", [])

                    if market_key == "h2h":
                        for outcome in outcomes:
                            odds_records.append({
                                "game_id": game_id,
                                "bookmaker_key": bookmaker_key,
                                "bookmaker_title": bookmaker_title,
                                "last_update": last_update,
                                "market_type": "h2h",
                                "team": outcome.get("name"),
                                "price": outcome.get("price"),
                            })

                    elif market_key == "spreads":
                        for outcome in outcomes:
                            odds_records.append({
                                "game_id": game_id,
                                "bookmaker_key": bookmaker_key,
                                "bookmaker_title": bookmaker_title,
                                "last_update": last_update,
                                "market_type": "spread",
                                "team": outcome.get("name"),
                                "point": outcome.get("point"),
                                "price": outcome.get("price"),
                            })

                    elif market_key == "totals":
                        for outcome in outcomes:
                            odds_records.append({
                                "game_id": game_id,
                                "bookmaker_key": bookmaker_key,
                                "bookmaker_title": bookmaker_title,
                                "last_update": last_update,
                                "market_type": "totals",
                                "outcome_name": outcome.get("name"),
                                "point": outcome.get("point"),
                                "price": outcome.get("price"),
                            })

                if odds_records:
                    for record in odds_records:
                        try:
                            await anyio.to_thread.run_sync(
                                lambda r=record: supabase.table("odds").upsert(
                                    [r], on_conflict="id"
                                ).execute()
                            )
                        except Exception as e:
                            print(f"Error saving odds record: {e}")

        except Exception as e:
            print(f"Error processing event {event.get('id')}: {e}")


async def scrape_all_data(supabase: Client):
    """Main function to scrape all data"""
    try:
        print(f"[{datetime.now().isoformat()}] Starting scrape...")

        teams = await get_teams_data()
        print(f"Fetched {len(teams)} teams")
        await save_teams(supabase, teams)

        odds_data = await get_nba_odds()
        # Support both list and dict return shapes
        events = odds_data if isinstance(odds_data, list) else odds_data.get('events', [])
        print(f"Fetched odds for {len(events)} games")
        await process_odds_data(supabase, odds_data)

        print(f"[{datetime.now().isoformat()}] Scrape completed successfully")
    except Exception as e:
        print(f"Error during scrape: {e}")


async def get_team_roster(team_abbrev: str, season: str = "2025"):
    """Scrape team roster from Basketball-Reference"""
    async with httpx.AsyncClient() as client:
        url = f"https://www.basketball-reference.com/teams/{team_abbrev.upper()}/{season}.html"
        
        try:
            response = await client.get(url, headers={
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            })
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            print(f"Failed to fetch roster for {team_abbrev}: {e}")
            return []

        soup = BeautifulSoup(response.content, "html.parser")
        players = []
        
        # Find the roster table
        roster_table = soup.find("table", {"id": "roster"})
        if not roster_table:
            print(f"No roster table found for {team_abbrev}")
            return players

        for row in roster_table.find_all("tr")[1:]:  # Skip header
            cells = row.find_all(["td", "th"])
            if len(cells) < 6:
                continue
                
            try:
                # Extract player data from Basketball-Reference roster table
                player_link = cells[1].find("a")
                if not player_link:
                    continue
                    
                name = player_link.text.strip()
                basketball_reference_url = "https://www.basketball-reference.com" + player_link["href"]
                
                # Extract Basketball-Reference ID from URL (e.g., /players/j/jamesle01.html -> jamesle01)
                basketball_reference_id = player_link["href"].split("/")[-1].replace(".html", "")
                
                # Parse other data
                jersey_number = cells[0].text.strip()
                try:
                    jersey_number = int(jersey_number) if jersey_number.isdigit() else None
                except:
                    jersey_number = None
                    
                position = cells[2].text.strip() if len(cells) > 2 else ""
                height = cells[3].text.strip() if len(cells) > 3 else ""
                weight_text = cells[4].text.strip() if len(cells) > 4 else ""
                
                # Parse weight
                weight = None
                if weight_text:
                    weight_match = re.search(r'(\d+)', weight_text)
                    if weight_match:
                        weight = int(weight_match.group(1))
                
                # Birth date (if available)
                birth_date = None
                birth_text = cells[5].text.strip() if len(cells) > 5 else ""
                if birth_text and len(birth_text) > 4:
                    try:
                        # Try to parse date in format like "January 1, 1990"
                        from datetime import datetime as dt
                        birth_date = dt.strptime(birth_text, "%B %d, %Y").date().isoformat()
                    except:
                        # If parsing fails, store as text for manual review
                        pass
                
                # Experience (if available in table)
                experience = None
                if len(cells) > 7:
                    exp_text = cells[7].text.strip()
                    if exp_text.isdigit():
                        experience = int(exp_text)
                    elif exp_text == "R":  # Rookie
                        experience = 0
                
                # College (if available)
                college = ""
                if len(cells) > 6:
                    college = cells[6].text.strip()
                
                player_data = {
                    "name": name,
                    "team_abbreviation": team_abbrev.upper(),
                    "jersey_number": jersey_number,
                    "position": position,
                    "height": height,
                    "weight": weight,
                    "birth_date": birth_date,
                    "experience": experience,
                    "college": college,
                    "basketball_reference_id": basketball_reference_id,
                    "basketball_reference_url": basketball_reference_url,
                    "is_active": True,
                    "season_year": f"{int(season)-1}-{season[2:]}"  # e.g., 2024-25
                }
                
                players.append(player_data)
                
            except Exception as e:
                print(f"Error parsing player row for {team_abbrev}: {e}")
                continue
                
        print(f"Found {len(players)} players for {team_abbrev}")
        return players


async def save_players(supabase: Client, players: list):
    """Save players to Supabase database"""
    if not players:
        return
        
    success_count = 0
    error_count = 0
    
    for player in players:
        try:
            # First, get team_id from teams table
            team_result = await anyio.to_thread.run_sync(
                lambda: supabase.table("teams")
                .select("id")
                .eq("abbreviation", player["team_abbreviation"])
                .execute()
            )
            
            if team_result.data:
                player["team_id"] = team_result.data[0]["id"]
            else:
                print(f"Warning: Team {player['team_abbreviation']} not found in teams table")
                player["team_id"] = None
            
            # Upsert player data
            await anyio.to_thread.run_sync(
                lambda p=player: supabase.table("players").upsert(
                    [p], on_conflict="name,team_abbreviation,season_year"
                ).execute()
            )
            success_count += 1
            
        except Exception as e:
            print(f"Error saving player {player.get('name', 'Unknown')} ({player.get('team_abbreviation')}): {e}")
            error_count += 1
            
    print(f"Players saved: {success_count} success, {error_count} errors")


async def scrape_all_team_rosters(supabase: Client, season: str = "2025"):
    """Scrape rosters for all teams"""
    try:
        print(f"[{datetime.now().isoformat()}] Starting roster scrape for season {season}...")
        
        # Get all teams from database
        teams_result = await anyio.to_thread.run_sync(
            lambda: supabase.table("teams").select("abbreviation").execute()
        )
        
        if not teams_result.data:
            print("No teams found in database. Please scrape teams first.")
            return
            
        total_teams = len(teams_result.data)
        total_players = 0
        
        for i, team in enumerate(teams_result.data, 1):
            team_abbrev = team["abbreviation"]
            print(f"[{i}/{total_teams}] Scraping roster for {team_abbrev}...")
            
            try:
                players = await get_team_roster(team_abbrev, season)
                await save_players(supabase, players)
                total_players += len(players)
                
                # Small delay to be respectful to Basketball-Reference
                await asyncio.sleep(1)
                
            except Exception as e:
                print(f"Error scraping roster for {team_abbrev}: {e}")
                continue
                
        print(f"[{datetime.now().isoformat()}] Roster scrape completed: {total_players} players from {total_teams} teams")
        
    except Exception as e:
        print(f"Error during roster scrape: {e}")


async def get_bulls_players_data():
    """Scrape Chicago Bulls players using advanced anti-bot protection"""
    try:
        logger.info("Starting Bulls players scraping with anti-bot protection")
        players = await scrape_bulls_players()
        logger.info(f"Successfully scraped {len(players)} Bulls players")
        return players
    except Exception as e:
        logger.error(f"Failed to scrape Bulls players: {e}")
        return []


async def save_bulls_players(supabase: Client, players: list):
    """Save Bulls players to Supabase with season-aware upsert and team_id mapping"""
    if not players:
        logger.warning("No Bulls players to save")
        return
    
    try:
        season_year = _current_season_year_str()

        # Fetch Bulls team_id once
        team_result = await anyio.to_thread.run_sync(
            lambda: supabase.table("teams").select("id").eq("abbreviation", "CHI").single().execute()
        )
        team_id = team_result.data.get("id") if getattr(team_result, "data", None) else None

        prepared = []
        for player in players:
            rec = dict(player)
            rec["team_abbreviation"] = "CHI"
            rec.setdefault("season_year", season_year)
            if team_id is not None:
                rec["team_id"] = team_id
            prepared.append(rec)

        # Bulk upsert for efficiency
        await anyio.to_thread.run_sync(
            lambda: supabase.table("players").upsert(
                prepared, on_conflict="name,team_abbreviation,season_year"
            ).execute()
        )

        logger.info(f"Successfully saved {len(prepared)} Bulls players to database (season {season_year})")
    except Exception as e:
        logger.error(f"Error saving Bulls players: {e}")


async def scrape_all_data(supabase: Client, include_rosters: bool = True):
    """Main function to scrape all data including rosters"""
    try:
        print(f"[{datetime.now().isoformat()}] Starting full scrape...")

        # Scrape teams first
        teams = await get_teams_data()
        print(f"Fetched {len(teams)} teams")
        await save_teams(supabase, teams)

        # Scrape odds
        odds_data = await get_nba_odds()
        events = odds_data if isinstance(odds_data, list) else odds_data.get('events', [])
        print(f"Fetched odds for {len(events)} games")
        await process_odds_data(supabase, odds_data)
        
        # Scrape rosters if requested
        if include_rosters:
            await scrape_all_team_rosters(supabase)
        
        # Specifically scrape Bulls players with advanced anti-bot protection
        bulls_players = await get_bulls_players_data()
        if bulls_players:
            await save_bulls_players(supabase, bulls_players)

        print(f"[{datetime.now().isoformat()}] Full scrape completed successfully")
    except Exception as e:
        print(f"Error during full scrape: {e}")
