# NBA External API Integration
# Integrates with external APIs like balldontlie.io for NBA data and odds providers

import asyncio
import aiohttp
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)

# API Configuration
BALLDONTLIE_BASE = "https://api.balldontlie.io/v1"
BALLDONTLIE_API_KEY = os.getenv("BALLDONTLIE_API_KEY")  # Optional - some endpoints don't require auth

# Sample odds API configuration (you would use TheOddsAPI or similar)
ODDS_API_BASE = "https://api.the-odds-api.com/v4"
ODDS_API_KEY = os.getenv("ODDS_API_KEY")

class NBADataFetcher:
    """Fetches NBA data from balldontlie.io API"""
    
    def __init__(self):
        self.session = None
        self.headers = {}
        if BALLDONTLIE_API_KEY:
            self.headers["Authorization"] = f"Bearer {BALLDONTLIE_API_KEY}"
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession(headers=self.headers)
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
                "dateFormat": "iso"
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    # Transform to match our expected format
                    transformed_odds = []
                    for game in data:
                        game_odds = {
                            "gameId": game["id"],
                            "homeTeam": game["home_team"],
                            "awayTeam": game["away_team"],
                            "startTime": game["commence_time"],
                            "bookmakers": []
                        }
                        
                        for bookmaker in game.get("bookmakers", []):
                            bm_data = {
                                "name": bookmaker["title"],
                                "moneyline": {"home": 0, "away": 0},
                                "spread": {"line": 0, "home": 0, "away": 0},
                                "total": {"line": 0, "over": 0, "under": 0}
                            }
                            
                            for market in bookmaker.get("markets", []):
                                if market["key"] == "h2h":
                                    outcomes = market["outcomes"]
                                    for outcome in outcomes:
                                        if outcome["name"] == game["home_team"]:
                                            bm_data["moneyline"]["home"] = outcome["price"]
                                        else:
                                            bm_data["moneyline"]["away"] = outcome["price"]
                                
                                elif market["key"] == "spreads":
                                    outcomes = market["outcomes"]
                                    for outcome in outcomes:
                                        if outcome["name"] == game["home_team"]:
                                            bm_data["spread"]["home"] = outcome["price"]
                                            bm_data["spread"]["line"] = outcome["point"]
                                        else:
                                            bm_data["spread"]["away"] = outcome["price"]
                                
                                elif market["key"] == "totals":
                                    outcomes = market["outcomes"]
                                    for outcome in outcomes:
                                        if outcome["name"] == "Over":
                                            bm_data["total"]["over"] = outcome["price"]
                                            bm_data["total"]["line"] = outcome["point"]
                                        else:
                                            bm_data["total"]["under"] = outcome["price"]
                            
                            game_odds["bookmakers"].append(bm_data)
                        
                        transformed_odds.append(game_odds)
                    
                    logger.info(f"Fetched odds for {len(transformed_odds)} games")
                    return transformed_odds
                else:
                    logger.error(f"Error fetching odds: {response.status}")
                    return self._get_mock_odds()
        except Exception as e:
            logger.error(f"Exception fetching odds: {e}")
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
    'fetch_nba_teams',
    'fetch_nba_players',
    'fetch_nba_games',
    'fetch_player_stats',
    'fetch_live_odds',
    'fetch_player_by_id'
]