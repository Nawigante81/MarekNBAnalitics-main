#!/usr/bin/env python3
"""
Test script to validate backend imports and basic functionality
"""

try:
    print("Testing FastAPI import...")
    from fastapi import FastAPI
    print("✅ FastAPI imported successfully")
    
    print("Testing main module...")
    import main
    print("✅ Main module imported successfully")
    
    print("Testing Supabase import...")
    from supabase import create_client
    print("✅ Supabase imported successfully")
    
    print("Testing APScheduler import...")
    from apscheduler.schedulers.asyncio import AsyncIOScheduler
    print("✅ APScheduler imported successfully")
    
    print("\n🎉 All backend imports successful!")
    print("Backend is ready to run!")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)