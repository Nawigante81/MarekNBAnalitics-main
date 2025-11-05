# 🚀 Quick Start Guide - NBA Analysis & Betting System

> **Szybkie uruchomienie w 5 minut dla wszystkich platform**

## ⚡ Immediate Setup (5 minutes)

### 1. **Clone and setup**

**Windows:**

```bash
setup.bat
```

**Mac/Linux:**

```bash
chmod +x setup.sh && ./setup.sh
```

### 2. **Configure environment**

Edit `.env` file with your API keys:

```bash
# Edit .env file with your API keys
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
VITE_ODDS_API_KEY=your_odds_api_key_here
```

### 3. **Run the application**

**Method 1 - Automated (Recommended):**

```bash
# Windows
start.bat

# Linux/Mac  
./start.sh
```

**Method 2 - Docker:**

```bash
# Windows
docker-start.bat

# Linux/Mac
docker-compose up -d
```

**Method 3 - Manual:**

```bash
# Terminal 1 - Backend
cd backend && source venv/bin/activate && python main.py

# Terminal 2 - Frontend  
npm run dev
```

### 4. **Access the application**

- **Frontend**: <http://localhost:5173>
- **Backend API**: <http://localhost:8000>
- **API Documentation**: <http://localhost:8000/docs>

---

## 🎯 Key Features Available Immediately

- **Dashboard**: Overview of NBA games and Bulls analysis
- **Reports**: Automated 7:50 AM, 8:00 AM, and 11:00 AM reports
- **Bulls Analysis**: Deep-dive Chicago Bulls player analytics
- **Betting Recommendations**: Kelly Criterion optimized suggestions
- **Live Odds**: Real-time odds monitoring and arbitrage detection

---

## 🔧 Configuration Options

### Database (Supabase)

1. Create Supabase project
2. Import SQL schema from `/supabase/migrations/`
3. Add connection details to `.env`

### API Keys

- **The Odds API**: For live betting odds
- **NBA API**: For player statistics  
- **Supabase**: For database access

---

## 📞 Need Help?

- Check the full README.md for detailed setup
- API Documentation: <http://localhost:8000/docs>
- Frontend runs on port 5173
- Backend runs on port 8000

---

## ⚡ Production Deployment

```bash
# Build for production
npm run build

# Deploy with Docker
docker-compose up -d
```

---

## 🏀 Happy Betting! 💰
