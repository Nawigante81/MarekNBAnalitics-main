#!/usr/bin/env python3
"""
Health check script for NBA Analytics Backend
Uses Python instead of curl for Docker healthcheck
"""
import sys
import urllib.request
import urllib.error

def check_health():
    """Check if backend service is healthy"""
    try:
        with urllib.request.urlopen("http://localhost:8000/health", timeout=5) as response:
            if response.status == 200:
                print("Service is healthy")
                return 0
            else:
                print(f"Service returned status: {response.status}")
                return 1
    except urllib.error.URLError as e:
        print(f"Health check failed: {e}")
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(check_health())