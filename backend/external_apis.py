# NBA External API Integration
# Integrates with external APIs like balldontlie.io for NBA data and odds providers

import asyncio
import aiohttp
import os
import time
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any, Union
import logging

logger = logging.getLogger(__name__)

# API Configuration
BALLDONTLIE_BASE = "https://api.balldontlie.io/v1"
BALLDONTLIE_API_KEY = os.getenv("BALLDONTLIE_API_KEY")  # Optional - some endpoints don't require auth

# Sample odds API configuration (you would use TheOddsAPI or similar)
ODDS_API_BASE = "https://api.the-odds-api.com/v4"
ODDS_API_KEY = os.getenv("ODDS_API_KEY")
ODDS_CACHE_TTL_SECONDS = int(os.getenv("ODDS_CACHE_TTL_SECONDS", "20"))  # 15-30s suggested

# Simple in-memory cache for odds to avoid hammering provider
_ODDS_CACHE_DATA: Optional[List[Dict[str, Any]]] = None
_ODDS_CACHE_TS: float = 0.0


class ExternalAPIError(Exception):
    """Represents an upstream provider error (non-200 or malformed response)."""

    def __init__(self, message: str, status: Optional[int] = None):
        super().__init__(message)
        self.status = status

class NBADataFetcher:
    """Fetches NBA data from balldontlie.io API"""
    
    def __init__(self):
        self.session = None
        self.headers = {}
        if BALLDONTLIE_API_KEY:
            self.headers["Authorization"] = f"Bearer {BALLDONTLIE_API_KEY}"
    
    async def __aenter__(self):
        timeout = aiohttp.ClientTimeout(total=6)  # seconds
        self.session = aiohttp.ClientSession(headers=self.headers, timeout=timeout)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_teams(self) -> List[Dict[str, Any]]:
        """Get all NBA teams"""
        try:
            if not self.session:
                self.session = aiohttp.ClientSession(headers=self.headers)
            
            url = f"{BALLDONTLIE_BASE}/teams"
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    teams = data.get("data", [])
                    
                    # Transform to match our database schema
                    transformed_teams = []
                    for team in teams:
                        transformed_teams.append({
                            "id": str(team["id"]),
                            "abbreviation": team["abbreviation"],
                            "full_name": team["full_name"],
                            "name": team["name"],
                            "city": team["city"],
                            "conference": team["conference"],
                            "division": team["division"]
                        })
                    
                    logger.info(f"Fetched {len(transformed_teams)} teams from balldontlie.io")
                    return transformed_teams
                else:
                    logger.error(f"Error fetching teams: {response.status}")
                    return []
        except Exception as e:
            logger.error(f"Exception fetching teams: {e}")
            return []
    
    async def get_players(self, team_id: Optional[str] = None, search: Optional[str] = None, per_page: int = 100) -> List[Dict[str, Any]]:
        """Get NBA players, optionally filtered by team or search query"""
        try:
            if not self.session:
                self.session = aiohttp.ClientSession(headers=self.headers)
            
            url = f"{BALLDONTLIE_BASE}/players"
            params = {"per_page": per_page}
            
            if team_id:
                params["team_ids[]"] = team_id
            if search:
                params["search"] = search
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    players = data.get("data", [])
                    
                    # Transform to match our database schema
                    transformed_players = []
                    for player in players:
                        transformed_players.append({
                            "id": str(player["id"]),
                            "name": f"{player['first_name']} {player['last_name']}",
                            "first_name": player["first_name"],
                            "last_name": player["last_name"],
                            "position": player["position"] or "N/A",
                            "jersey_number": player.get("jersey_number"),
                            "height": player.get("height"),
                            "weight": player.get("weight"),
                            "team_abbreviation": player["team"]["abbreviation"] if player.get("team") else None,
                            "team_id": str(player["team"]["id"]) if player.get("team") else None,
                            "is_active": True,  # balldontlie.io only returns active players
                            "season_year": "2024-25"
                        })
                    
                    logger.info(f"Fetched {len(transformed_players)} players from balldontlie.io")
                    return transformed_players
                else:
                    logger.error(f"Error fetching players: {response.status}")
                    return []
        except Exception as e:
            logger.error(f"Exception fetching players: {e}")
            return []
    
    async def get_games(self, start_date: Optional[str] = None, end_date: Optional[str] = None, team_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get NBA games for a date range"""
        try:
            if not self.session:
                self.session = aiohttp.ClientSession(headers=self.headers)
            
            url = f"{BALLDONTLIE_BASE}/games"
            params = {"per_page": 100}
            
            if start_date:
                params["start_date"] = start_date
            if end_date:
                params["end_date"] = end_date
            if team_id:
                params["team_ids[]"] = team_id
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    games = data.get("data", [])
                    
                    # Transform to match our database schema
                    transformed_games = []
                    for game in games:
                        transformed_games.append({
                            "id": str(game["id"]),
                            "home_team": game["home_team"]["full_name"],
                            "home_team_abbreviation": game["home_team"]["abbreviation"],
                            "away_team": game["visitor_team"]["full_name"],
                            "away_team_abbreviation": game["visitor_team"]["abbreviation"],
                            "commence_time": game["date"],
                            "status": game["status"],
                            "home_team_score": game.get("home_team_score"),
                            "visitor_team_score": game.get("visitor_team_score"),
                            "season": game.get("season", 2024),
                            "postseason": game.get("postseason", False)
                        })
                    
                    logger.info(f"Fetched {len(transformed_games)} games from balldontlie.io")
                    return transformed_games
                else:
                    logger.error(f"Error fetching games: {response.status}")
                    return []
        except Exception as e:
            logger.error(f"Exception fetching games: {e}")
            return []
    
    async def get_player_stats(self, player_id: str, season: int = 2024) -> List[Dict[str, Any]]:
        """Get player statistics for a season"""
        try:
            if not self.session:
                self.session = aiohttp.ClientSession(headers=self.headers)
            
            url = f"{BALLDONTLIE_BASE}/season_averages"
            params = {
                "player_ids[]": player_id,
                "season": season
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    stats = data.get("data", [])
                    
                    if stats:
                        stat = stats[0]  # Should only be one result
                        return {
                            "player_id": player_id,
                            "season": season,
                            "games_played": stat.get("games_played", 0),
                            "ppg": stat.get("pts", 0.0),
                            "rpg": stat.get("reb", 0.0),
                            "apg": stat.get("ast", 0.0),
                            "field_goals_made": stat.get("fgm", 0.0),
                            "field_goals_attempted": stat.get("fga", 0.0),
                            "fg_percentage": stat.get("fg_pct", 0.0),
                            "three_pointers_made": stat.get("fg3m", 0.0),
                            "three_pointers_attempted": stat.get("fg3a", 0.0),
                            "three_point_percentage": stat.get("fg3_pct", 0.0),
                            "free_throws_made": stat.get("ftm", 0.0),
                            "free_throws_attempted": stat.get("fta", 0.0),
                            "ft_percentage": stat.get("ft_pct", 0.0),
                            "steals": stat.get("stl", 0.0),
                            "blocks": stat.get("blk", 0.0),
                            "turnovers": stat.get("turnover", 0.0),
                            "minutes_per_game": stat.get("min", "0:00")
                        }
                    else:
                        return {}
                else:
                    logger.error(f"Error fetching player stats: {response.status}")
                    return {}
        except Exception as e:
            logger.error(f"Exception fetching player stats: {e}")
            return {}


class OddsDataFetcher:
    """Fetches betting odds data from odds providers"""
    
    def __init__(self):
        self.session = None
        self.headers = {}
        if ODDS_API_KEY:
            self.headers["x-rapidapi-key"] = ODDS_API_KEY
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession(headers=self.headers)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def _normalize_games_payload(self, payload: Union[List[Any], Dict[str, Any], None]) -> List[Dict[str, Any]]:
        """Normalize various upstream payload shapes to a list of game dicts."""
        if payload is None:
            return []
        if isinstance(payload, list):
            # Ensure elements are dicts
            return [g for g in payload if isinstance(g, dict)]
        if isinstance(payload, dict):
            for key in ("data", "events", "games", "matches", "response"):
                val = payload.get(key)
                if isinstance(val, list):
                    return [g for g in val if isinstance(g, dict)]
            # Single game object edge-case
            if payload.get("id") and (payload.get("bookmakers") or payload.get("sites")):
                return [payload]
        return []

    def _coerce_team_name(self, value: Any) -> str:
        """Coerce upstream team representation (str or dict) to a readable name/abbr."""
        if isinstance(value, str):
            return value
        if isinstance(value, dict):
            # Prefer full name, then name, then abbreviation-like fields
            return (
                value.get("full_name")
                or value.get("name")
                or value.get("abbreviation")
                or value.get("key")
                or value.get("team")
                or ""
            )
        return ""

    async def get_live_odds(self, sport: str = "basketball_nba") -> List[Dict[str, Any]]:
        """Get live odds for NBA games"""
        try:
            if not ODDS_API_KEY:
                logger.warning("No odds API key configured - returning mock data")
                return self._get_mock_odds()
            
            if not self.session:
                self.session = aiohttp.ClientSession(headers=self.headers)
            
            url = f"{ODDS_API_BASE}/sports/{sport}/odds"
            params = {
                "regions": "us",
                "markets": "h2h,spreads,totals",
                "oddsFormat": "american",
                "dateFormat": "iso",
            }
            # The Odds API expects apiKey as a query parameter; include it defensively
            params["apiKey"] = ODDS_API_KEY
            
            # Serve from cache if fresh
            now = time.time()
            global _ODDS_CACHE_DATA, _ODDS_CACHE_TS
            if _ODDS_CACHE_DATA is not None and (now - _ODDS_CACHE_TS) < ODDS_CACHE_TTL_SECONDS:
                logger.info("Serving odds from in-memory cache")
                return _ODDS_CACHE_DATA

            async with self.session.get(url, params=params) as response:
                if response.status != 200:
                    # Read a short prefix of the upstream body to aid debugging
                    try:
                        body_preview = (await response.text())[:500]
                    except Exception:
                        body_preview = "<unreadable>"
                    logger.error(
                        f"Upstream odds provider non-200: status={response.status}; body_prefix={body_preview}"
                    )
                    # Fallback to cache if available
                    if _ODDS_CACHE_DATA is not None and (time.time() - _ODDS_CACHE_TS) < max(ODDS_CACHE_TTL_SECONDS, 10):
                        logger.warning("Returning cached odds due to upstream error")
                        return _ODDS_CACHE_DATA
                    raise ExternalAPIError(f"odds upstream returned {response.status}", status=response.status)

                # Parse payload defensively (could be list or dict wrapper)
                try:
                    raw = await response.json(content_type=None)
                except Exception as je:
                    logger.error(f"Failed to parse odds JSON: {je}")
                    raise ExternalAPIError("invalid JSON from odds upstream")

                games = self._normalize_games_payload(raw)

                # Transform to match our expected format
                transformed_odds: List[Dict[str, Any]] = []
                for game in games:
                    home_raw = game.get("home_team")
                    away_raw = game.get("away_team")
                    home_name = self._coerce_team_name(home_raw)
                    away_name = self._coerce_team_name(away_raw)

                    game_odds: Dict[str, Any] = {
                        "gameId": game.get("id") or game.get("game_id") or "",
                        "homeTeam": home_name,
                        "awayTeam": away_name,
                        "startTime": game.get("commence_time") or game.get("start_time") or game.get("date"),
                        "bookmakers": [],
                    }

                    # Support both TheOddsAPI 'bookmakers' and some providers 'sites'
                    bookmakers = game.get("bookmakers") or game.get("sites") or []
                    for bookmaker in bookmakers:
                        name = (
                            bookmaker.get("title")
                            or bookmaker.get("name")
                            or bookmaker.get("key")
                            or "unknown"
                        )
                        bm_data: Dict[str, Any] = {
                            "name": name,
                            "moneyline": {"home": None, "away": None},
                            "spread": {"line": None, "home": None, "away": None},
                            "total": {"line": None, "over": None, "under": None},
                        }

                        markets = bookmaker.get("markets") or bookmaker.get("odds") or []
                        for market in markets:
                            key = market.get("key") or market.get("market")
                            outcomes = market.get("outcomes") or market.get("outcome") or []
                            if key == "h2h":
                                for outcome in outcomes:
                                    oname = outcome.get("name") or outcome.get("team")
                                    price = outcome.get("price") or outcome.get("odds")
                                    if oname == home_name:
                                        bm_data["moneyline"]["home"] = price
                                    elif oname == away_name:
                                        bm_data["moneyline"]["away"] = price
                            elif key == "spreads":
                                for outcome in outcomes:
                                    oname = outcome.get("name") or outcome.get("team")
                                    price = outcome.get("price") or outcome.get("odds")
                                    point = outcome.get("point") or outcome.get("line")
                                    if oname == home_name:
                                        bm_data["spread"]["home"] = price
                                        bm_data["spread"]["line"] = point
                                    elif oname == away_name:
                                        bm_data["spread"]["away"] = price
                                        # If line missing on away, keep whatever was set for home
                            elif key == "totals":
                                for outcome in outcomes:
                                    oname = (outcome.get("name") or outcome.get("label") or "").lower()
                                    price = outcome.get("price") or outcome.get("odds")
                                    point = outcome.get("point") or outcome.get("line")
                                    if "over" in oname:
                                        bm_data["total"]["over"] = price
                                        bm_data["total"]["line"] = point
                                    elif "under" in oname:
                                        bm_data["total"]["under"] = price

                        game_odds["bookmakers"].append(bm_data)

                    transformed_odds.append(game_odds)

                logger.info(f"Fetched odds for {len(transformed_odds)} games")
                # Update cache
                _ODDS_CACHE_DATA = transformed_odds
                _ODDS_CACHE_TS = time.time()
                return transformed_odds
        except Exception as e:
            # If upstream error and cache available, use cache; otherwise follow previous behavior
            if isinstance(e, ExternalAPIError):
                if _ODDS_CACHE_DATA is not None and (time.time() - _ODDS_CACHE_TS) < max(ODDS_CACHE_TTL_SECONDS, 10):
                    logger.warning("Returning cached odds due to upstream exception")
                    return _ODDS_CACHE_DATA
                raise
            logger.error(f"Exception fetching odds: {e}")
            if _ODDS_CACHE_DATA is not None and (time.time() - _ODDS_CACHE_TS) < max(ODDS_CACHE_TTL_SECONDS, 10):
                logger.warning("Returning cached odds due to exception")
                return _ODDS_CACHE_DATA
            return self._get_mock_odds()
    
    def _get_mock_odds(self) -> List[Dict[str, Any]]:
        """Fallback mock odds data"""
        return [
            {
                "gameId": "mock-bulls-lakers",
                "homeTeam": "Chicago Bulls",
                "awayTeam": "Los Angeles Lakers",
                "startTime": (datetime.now() + timedelta(hours=2)).isoformat(),
                "bookmakers": [
                    {
                        "name": "DraftKings",
                        "moneyline": {"home": -120, "away": 100},
                        "spread": {"line": -2.5, "home": -110, "away": -110},
                        "total": {"line": 225.5, "over": -110, "under": -110}
                    },
                    {
                        "name": "FanDuel",
                        "moneyline": {"home": -115, "away": -105},
                        "spread": {"line": -2.0, "home": -105, "away": -115},
                        "total": {"line": 226.0, "over": -115, "under": -105}
                    }
                ],
                "movements": [
                    {
                        "type": "spread",
                        "direction": "up",
                        "from": -1.5,
                        "to": -2.5,
                        "time": "2 min ago"
                    }
                ]
            }
        ]


# Convenience functions for easy usage
async def fetch_nba_teams() -> List[Dict[str, Any]]:
    """Fetch NBA teams from external API"""
    async with NBADataFetcher() as fetcher:
        return await fetcher.get_teams()

async def fetch_nba_players(team_id: Optional[str] = None, search: Optional[str] = None) -> List[Dict[str, Any]]:
    """Fetch NBA players from external API"""
    async with NBADataFetcher() as fetcher:
        return await fetcher.get_players(team_id=team_id, search=search)

async def fetch_nba_games(start_date: Optional[str] = None, end_date: Optional[str] = None, team_id: Optional[str] = None) -> List[Dict[str, Any]]:
    """Fetch NBA games from external API"""
    async with NBADataFetcher() as fetcher:
        return await fetcher.get_games(start_date=start_date, end_date=end_date, team_id=team_id)

async def fetch_player_by_id(player_id: str) -> Dict[str, Any]:
    """Fetch single player by ID from external API"""
    async with NBADataFetcher() as fetcher:
        # Direct endpoint for player by id
        try:
            if not fetcher.session:
                fetcher.session = aiohttp.ClientSession(headers=fetcher.headers)
            url = f"{BALLDONTLIE_BASE}/players/{player_id}"
            async with fetcher.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    p = data or {}
                    return {
                        "id": str(p.get("id")),
                        "name": f"{p.get('first_name','')} {p.get('last_name','')}".strip(),
                        "first_name": p.get("first_name"),
                        "last_name": p.get("last_name"),
                        "position": p.get("position") or "N/A",
                        "jersey_number": p.get("jersey_number"),
                        "height": p.get("height"),
                        "weight": p.get("weight"),
                        "team_abbreviation": (p.get("team") or {}).get("abbreviation"),
                        "team_id": str((p.get("team") or {}).get("id")) if p.get("team") else None,
                        "is_active": True,
                        "season_year": "2024-25"
                    }
                else:
                    logger.error(f"Error fetching player {player_id}: {response.status}")
                    return {}
        except Exception as e:
            logger.error(f"Exception fetching player {player_id}: {e}")
            return {}

async def fetch_player_stats(player_id: str) -> Dict[str, Any]:
    """Fetch player statistics from external API"""
    async with NBADataFetcher() as fetcher:
        return await fetcher.get_player_stats(player_id)

async def fetch_live_odds() -> List[Dict[str, Any]]:
    """Fetch live odds from odds provider"""
    async with OddsDataFetcher() as fetcher:
        return await fetcher.get_live_odds()


# Export main classes and functions
__all__ = [
    'NBADataFetcher',
    'OddsDataFetcher', 
    'ExternalAPIError',
    'fetch_nba_teams',
    'fetch_nba_players',
    'fetch_nba_games',
    'fetch_player_stats',
    'fetch_live_odds',
    'fetch_player_by_id'
]