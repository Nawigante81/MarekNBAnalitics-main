"""
Advanced Anti-Bot Protection for NBA Data Scraping
=================================================
Comprehensive solution for bypassing Basketball-Reference anti-bot measures
"""

import asyncio
import random
import time
from typing import List, Dict, Optional, Any
import json
import os
import logging
from datetime import datetime, timedelta
from pathlib import Path

import httpx
import aiofiles
from fake_useragent import UserAgent
from bs4 import BeautifulSoup
import cloudscraper
from httpx_socks import AsyncProxyTransport

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AntiBottingScraper:
    """Advanced scraper with multiple anti-detection strategies"""
    
    def __init__(self):
        try:
            self.ua = UserAgent(platforms=['pc'], browsers=['chrome', 'firefox', 'safari'])
        except Exception:
            # Fallback user agent if fake-useragent fails
            self.ua = None
        
        self.session_cookies = {}
        self.request_delays = []
        self.proxy_list = []
        self.current_proxy_index = 0
        self.max_retries = 3
        self.base_delay = (2, 5)  # Random delay between requests (seconds)
        
        # Session management
        self.session_file = Path("session_data.json")
        # Initialize session data synchronously
        self.session_cookies = {}
        self.request_delays = []
        
    async def load_session_data(self):
        """Load persistent session data"""
        if self.session_file.exists():
            try:
                async with aiofiles.open(self.session_file, 'r') as f:
                    data = json.loads(await f.read())
                    self.session_cookies = data.get('cookies', {})
                    self.request_delays = data.get('delays', [])
            except Exception as e:
                logger.warning(f"Failed to load session data: {e}")
    
    async def save_session_data(self):
        """Save session data persistently"""
        try:
            data = {
                'cookies': self.session_cookies,
                'delays': self.request_delays[-50:],  # Keep last 50 delays
                'last_updated': datetime.now().isoformat()
            }
            async with aiofiles.open(self.session_file, 'w') as f:
                await f.write(json.dumps(data, indent=2))
        except Exception as e:
            logger.warning(f"Failed to save session data: {e}")
    
    def get_random_headers(self) -> Dict[str, str]:
        """Generate realistic browser headers"""
        # Fallback user agents if fake-useragent fails
        fallback_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        ]
        
        user_agent = self.ua.random if self.ua else random.choice(fallback_agents)
        
        headers = {
            'User-Agent': user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9,pl;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0',
        }
        
        # Sometimes include referer to mimic real browsing
        if random.choice([True, False]):
            referers = [
                'https://www.google.com/',
                'https://www.bing.com/',
                'https://duckduckgo.com/',
                'https://www.nba.com/',
                'https://espn.com/',
            ]
            headers['Referer'] = random.choice(referers)
            
        return headers
    
    async def smart_delay(self):
        """Intelligent delay based on recent request patterns"""
        # Base random delay
        base_delay = random.uniform(*self.base_delay)
        
        # Adjust based on recent delays (mimic human patterns)
        if len(self.request_delays) > 5:
            avg_delay = sum(self.request_delays[-5:]) / 5
            # Vary from recent pattern
            variation = random.uniform(-0.3, 0.3) * avg_delay
            base_delay += variation
        
        # Occasionally add longer delays (like humans taking breaks)
        if random.random() < 0.1:  # 10% chance
            base_delay += random.uniform(10, 30)
            logger.info(f"Taking extended break: {base_delay:.1f}s")
        
        # Store delay for pattern analysis
        self.request_delays.append(base_delay)
        if len(self.request_delays) > 100:
            self.request_delays = self.request_delays[-50:]
        
        await asyncio.sleep(base_delay)
    
    async def get_proxy_transport(self) -> Optional[AsyncProxyTransport]:
        """Get proxy transport if available"""
        if not self.proxy_list:
            return None
        
        proxy = self.proxy_list[self.current_proxy_index % len(self.proxy_list)]
        self.current_proxy_index += 1
        
        try:
            return AsyncProxyTransport.from_url(proxy)
        except Exception as e:
            logger.warning(f"Failed to create proxy transport: {e}")
            return None

    async def make_request(self, url: str, method: str = 'GET', **kwargs) -> Optional[httpx.Response]:
        """Make request with full anti-detection measures"""
        headers = self.get_random_headers()
        
        # Add session cookies if available
        cookies = self.session_cookies.get(url.split('/')[2], {})
        
        for attempt in range(self.max_retries):
            try:
                # Smart delay before request
                if attempt > 0:
                    await asyncio.sleep(random.uniform(5, 15))  # Longer delay on retries
                else:
                    await self.smart_delay()
                
                # Create client with anti-detection measures
                client_kwargs = {
                    'headers': headers,
                    'cookies': cookies,
                    'timeout': httpx.Timeout(30.0),
                    'follow_redirects': True,
                }
                
                # Add proxy if available
                proxy_transport = await self.get_proxy_transport()
                if proxy_transport:
                    client_kwargs['transport'] = proxy_transport
                
                async with httpx.AsyncClient(**client_kwargs) as client:
                    response = await client.request(method, url, **kwargs)
                    
                    # Update session cookies
                    if response.cookies:
                        domain = url.split('/')[2]
                        self.session_cookies[domain] = dict(response.cookies)
                    
                    # Check if we got blocked
                    if self.is_blocked_response(response):
                        logger.warning(f"Blocked response detected (attempt {attempt + 1})")
                        if attempt < self.max_retries - 1:
                            await asyncio.sleep(random.uniform(30, 60))  # Long delay if blocked
                            continue
                    
                    response.raise_for_status()
                    
                    # Save session data periodically
                    if random.random() < 0.1:  # 10% chance
                        await self.save_session_data()
                    
                    return response
                    
            except Exception as e:
                logger.warning(f"Request failed (attempt {attempt + 1}): {e}")
                if attempt < self.max_retries - 1:
                    # Exponential backoff with jitter
                    delay = (2 ** attempt) + random.uniform(0, 1)
                    await asyncio.sleep(delay)
                else:
                    logger.error(f"All retry attempts failed for {url}")
                    return None
        
        return None
    
    def is_blocked_response(self, response: httpx.Response) -> bool:
        """Detect if response indicates we're being blocked.
        Be conservative to avoid false positives on legitimate pages.
        """
        # Hard block by status codes
        if response.status_code in [403, 429, 503]:
            return True

        text = response.text.lower()

        # Allowlist: if page contains expected content markers, treat as not blocked
        expected_markers = [
            'id="roster"',
            'table id="roster"',
            'id="teams_active"',
            'table id="teams_active"',
        ]
        if any(marker in text for marker in expected_markers):
            return False

        # Strong block indicators
        strong_indicators = [
            'captcha',
            'cloudflare',
            'access denied',
            'attention required',
            'bot detected',
            'automated traffic',
            'suspicious activity',
            'rate limit',
            'too many requests',
        ]
        if any(ind in text for ind in strong_indicators):
            return True

        # Avoid treating generic occurrences of the word 'blocked' as a block
        # unless paired with other strong signals.
        return False
    
    async def cloudscraper_fallback(self, url: str) -> Optional[str]:
        """Fallback using cloudscraper for Cloudflare protected sites"""
        try:
            scraper = cloudscraper.create_scraper()
            response = scraper.get(url)
            return response.text
        except Exception as e:
            logger.error(f"Cloudscraper fallback failed: {e}")
            return None


class BasketballReferenceScraper(AntiBottingScraper):
    """Specialized scraper for Basketball-Reference with sport-specific optimizations"""
    
    def __init__(self):
        super().__init__()
        self.base_url = "https://www.basketball-reference.com"
        self._initialized = False
        
        # Sport-specific headers
        self.sport_headers = {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Cache-Control': 'no-cache',
        }
    
    async def initialize(self):
        """Initialize async components"""
        if not self._initialized:
            await self.load_session_data()
            self._initialized = True
    
    async def scrape_teams(self) -> List[Dict[str, Any]]:
        """Scrape NBA teams with anti-detection"""
        await self.initialize()
        
        url = f"{self.base_url}/teams/"
        logger.info(f"Scraping teams from {url}")
        
        response = await self.make_request(url)
        if not response:
            # Try cloudscraper fallback
            content = await self.cloudscraper_fallback(url)
            if not content:
                logger.error("Failed to scrape teams data")
                return []
        else:
            content = response.text
        
        return self.parse_teams_data(content)
    
    def parse_teams_data(self, html_content: str) -> List[Dict[str, Any]]:
        """Parse teams data from HTML"""
        soup = BeautifulSoup(html_content, "html.parser")
        teams = []
        
        table = soup.find("table", {"id": "teams_active"})
        if not table:
            logger.warning("Teams table not found")
            return teams
        
        for row in table.find_all("tr")[1:]:
            th = row.find("th")
            if not th:
                continue
            
            a = th.find("a")
            if not a:
                continue
            
            try:
                abbreviation = a["href"].split("/")[-2]
                full_name = a.text.strip()
                parts = full_name.split()
                
                team_data = {
                    "abbreviation": abbreviation.upper(),
                    "full_name": full_name,
                    "name": parts[-1] if parts else "",
                    "city": " ".join(parts[:-1]) if len(parts) > 1 else "",
                }
                teams.append(team_data)
                
            except Exception as e:
                logger.warning(f"Failed to parse team row: {e}")
                continue
        
        logger.info(f"Successfully parsed {len(teams)} teams")
        return teams
    
    async def scrape_team_roster(self, team_abbr: str, year: int = 2025) -> List[Dict[str, Any]]:
        """Scrape team roster with anti-detection"""
        await self.initialize()
        
        url = f"{self.base_url}/teams/{team_abbr.upper()}/{year}.html"
        logger.info(f"Scraping roster for {team_abbr} from {url}")
        
        response = await self.make_request(url)
        if not response:
            content = await self.cloudscraper_fallback(url)
            if not content:
                logger.error(f"Failed to scrape {team_abbr} roster")
                return []
        else:
            content = response.text
        
        return self.parse_roster_data(content, team_abbr)
    
    def parse_roster_data(self, html_content: str, team_abbr: str) -> List[Dict[str, Any]]:
        """Parse roster data from HTML"""
        soup = BeautifulSoup(html_content, "html.parser")
        players = []
        
        # Try multiple table selectors
        table_selectors = ["#roster", "#per_game", ".stats_table"]
        roster_table = None
        
        for selector in table_selectors:
            roster_table = soup.select_one(selector)
            if roster_table:
                break
        
        if not roster_table:
            logger.warning(f"No roster table found for {team_abbr}")
            return players
        
        for row in roster_table.find_all("tr")[1:]:  # Skip header
            try:
                cells = row.find_all(['td', 'th'])
                if len(cells) < 3:
                    continue
                
                # Extract player data (adjust based on actual table structure)
                name_cell = cells[0] if cells[0].find('a') else cells[1]
                name_link = name_cell.find('a')
                
                if name_link:
                    player_name = name_link.text.strip()
                    player_url = name_link.get('href', '')
                    
                    # Map roster table columns: No., Player, Pos, Ht, Wt, Birth Date, College, Exp
                    position = cells[2].text.strip() if len(cells) > 2 else ""
                    height = cells[3].text.strip() if len(cells) > 3 else ""

                    # Parse numeric weight if present
                    weight_val = None
                    if len(cells) > 4:
                        wt_text = cells[4].text.strip()
                        try:
                            import re as _re
                            _m = _re.search(r"(\d+)", wt_text)
                            if _m:
                                weight_val = int(_m.group(1))
                        except Exception:
                            weight_val = None

                    player_data = {
                        "name": player_name,
                        "team": team_abbr.upper(),
                        "position": position,
                        "height": height,
                        "weight": weight_val,
                        "profile_url": f"{self.base_url}{player_url}" if player_url else "",
                        "scraped_at": datetime.now().isoformat(),
                    }
                    
                    players.append(player_data)
                    
            except Exception as e:
                logger.warning(f"Failed to parse player row for {team_abbr}: {e}")
                continue
        
        logger.info(f"Successfully parsed {len(players)} players for {team_abbr}")
        return players


# Convenience functions for easy import
async def scrape_nba_teams() -> List[Dict[str, Any]]:
    """Scrape NBA teams with full anti-bot protection"""
    scraper = BasketballReferenceScraper()
    return await scraper.scrape_teams()


async def scrape_team_players(team_abbr: str) -> List[Dict[str, Any]]:
    """Scrape team players with full anti-bot protection"""
    scraper = BasketballReferenceScraper()
    return await scraper.scrape_team_roster(team_abbr)


async def scrape_bulls_players() -> List[Dict[str, Any]]:
    """Scrape Chicago Bulls players specifically"""
    return await scrape_team_players("CHI")


if __name__ == "__main__":
    # Test the scraper
    async def main():
        # Test teams scraping
        teams = await scrape_nba_teams()
        print(f"Scraped {len(teams)} teams")
        
        # Test Bulls players scraping
        if teams:
            bulls_players = await scrape_bulls_players()
            print(f"Scraped {len(bulls_players)} Bulls players")
    
    asyncio.run(main())