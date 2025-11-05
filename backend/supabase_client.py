"""
Isolated Supabase client to avoid httpx conflicts
"""
import os
from typing import Optional

try:
    # Import before any httpx-modifying libraries
    from supabase import create_client, Client
    SUPABASE_AVAILABLE = True
except ImportError as e:
    print(f"Supabase not available: {e}")
    SUPABASE_AVAILABLE = False
    Client = None

def create_isolated_supabase_client(url: str, key: str) -> Optional[Client]:
    """Create supabase client in isolated environment"""
    if not SUPABASE_AVAILABLE:
        return None
    
    try:
        return create_client(url, key)
    except Exception as e:
        print(f"Failed to create supabase client: {e}")
        return None

def get_supabase_config():
    """Get supabase configuration from environment"""
    url = os.getenv("SUPABASE_URL") or os.getenv("VITE_SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_KEY")
    anon_key = os.getenv("VITE_SUPABASE_ANON_KEY")
    
    return {
        "url": url,
        "service_key": service_key,
        "anon_key": anon_key,
        "available": bool(url and (service_key or anon_key))
    }