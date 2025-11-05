# 🏀 NBA Analytics - Complete Installation Guide

> **Comprehensive installation guide for all supported platforms**

---

## 🖥️ Supported Platforms

| Platform | Status | Method | Difficulty |
|----------|---------|---------|------------|
| **Windows 11** | ✅ Full Support | Native/Docker | Easy |
| **Windows 10** | ✅ Full Support | Native/Docker | Easy |
| **Ubuntu/Debian** | ✅ Full Support | Native/Docker | Easy |
| **macOS** | ✅ Full Support | Native/Docker | Easy |
| **Raspberry Pi 4** | ✅ Full Support | Native/Docker | Medium |
| **CentOS/RHEL** | ⚠️ Community | Native | Medium |
| **Arch Linux** | ⚠️ Community | Native | Medium |

---

## ⚡ Quick Platform Selection

### 🪟 Windows Users

**Recommended**: Use automated scripts for easiest setup

```cmd
# Download project and run:
setup.bat
start.bat
```

📖 **Detailed Guide**: [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)

### 🐧 Linux Users

**Recommended**: Use shell scripts

```bash
chmod +x setup.sh start.sh
./setup.sh
./start.sh
```

📖 **Detailed Guide**: [README.md](README.md)

### 🍎 macOS Users

**Recommended**: Use Homebrew + shell scripts

```bash
# Install dependencies with Homebrew
brew install node python@3.11
# Then run setup
chmod +x setup.sh && ./setup.sh
```

### 🥧 Raspberry Pi Users

**Recommended**: Use Docker for best performance

```bash
# ARM64 optimized deployment
docker-compose -f docker-compose.pi4.yml up -d
```

📖 **Detailed Guide**: [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)

### 🐳 Docker Users (Any Platform)

**Recommended**: For production deployments

```bash
docker-start.bat  # Windows
# OR
docker-compose up -d  # Linux/macOS
```

---

## 📋 System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|------------|
| **OS** | Windows 10+, Ubuntu 18.04+, macOS 10.15+ |
| **RAM** | 4GB (8GB recommended) |
| **Storage** | 2GB free space |
| **CPU** | 2+ cores |
| **Network** | Internet connection for APIs |

### Recommended Requirements

| Component | Recommendation |
|-----------|---------------|
| **RAM** | 8GB+ |
| **Storage** | 10GB+ (SSD preferred) |
| **CPU** | 4+ cores |
| **Network** | Stable broadband |

---

## 🔑 Required API Keys

Before installation, obtain these free API keys:

### 1. Supabase (Database)

1. Go to <https://supabase.com/>
2. Create account and new project
3. Get from Settings → API:
   - `Project URL` → `VITE_SUPABASE_URL`
   - `anon/public key` → `VITE_SUPABASE_ANON_KEY`

### 2. The Odds API (Betting Data)

1. Go to <https://the-odds-api.com/>
2. Sign up for free account (500 requests/month)
3. Get API key → `VITE_ODDS_API_KEY`

---

## 🚀 Installation Methods

### Method 1: Automated Scripts (Recommended)

**Advantages**: ✅ Easiest, ✅ Error handling, ✅ Cross-platform

| Platform | Setup Script | Start Script |
|----------|-------------|-------------|
| Windows | `setup.bat` | `start.bat` |
| Linux/macOS | `setup.sh` | `start.sh` |

### Method 2: Docker (Production)

**Advantages**: ✅ Consistent environment, ✅ Easy deployment, ✅ Isolated

```bash
# Windows
docker-start.bat

# Linux/macOS/Pi
docker-compose up -d
```

### Method 3: Manual Installation

**Advantages**: ✅ Full control, ✅ Development setup

1. Install Node.js 18+ and Python 3.8+
2. Clone repository
3. Install dependencies manually
4. Configure environment
5. Start services

---

## 🔧 Troubleshooting Guide

### Common Issues

#### ❌ "node/python not found"

**Solution**: Add to system PATH or reinstall with PATH option

#### ❌ "Permission denied"

**Linux/macOS**: Make scripts executable: `chmod +x *.sh`
**Windows**: Run as Administrator

#### ❌ "Port already in use"

**Solution**: Kill processes on ports 8000/5173:

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/macOS
lsof -ti:8000 | xargs kill -9
```

#### ❌ Docker issues

**Solution**: Ensure Docker Desktop is running and updated

#### ❌ Out of memory (Pi/Low-spec)

**Solution**: Use minimal requirements:

```bash
cd backend
pip install -r requirements-minimal.txt
```

### Platform-Specific Issues

#### Windows PowerShell Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### macOS Rosetta (M1/M2 Macs)

Some dependencies may need Rosetta:

```bash
softwareupdate --install-rosetta
```

#### Linux Missing Build Tools

```bash
sudo apt install build-essential python3-dev
# or
sudo yum groupinstall "Development Tools"
```

---

## 📊 Installation Verification

After installation, verify everything works:

### 1. Check Services

```bash
# Frontend (should load dashboard)
curl http://localhost:5173

# Backend API (should return "healthy")
curl http://localhost:8000/health

# API Documentation (should load Swagger UI)
# Open: http://localhost:8000/docs
```

### 2. Test Database Connection

```bash
# Check teams endpoint
curl http://localhost:8000/api/teams

# Should return NBA teams data
```

### 3. Verify Environment

Check `.env` file contains:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_ODDS_API_KEY=your-odds-key
```

---

## 📁 Project Structure After Installation

```
MarekNBAnalitics/
├── 📱 Frontend (React + Vite)
│   ├── src/                 # Source code
│   ├── node_modules/        # Dependencies
│   └── package.json         # Config
├── 🐍 Backend (FastAPI)
│   ├── main.py              # API server
│   ├── venv/                # Python environment
│   └── requirements.txt     # Dependencies
├── 🐳 Docker
│   ├── docker-compose.yml   # Container setup
│   └── Dockerfile.*         # Build configs
├── 📋 Documentation
│   ├── README.md            # Main docs
│   ├── QUICKSTART*.md       # Platform guides
│   └── TROUBLESHOOTING*.md  # Problem solving
└── ⚙️ Configuration
    ├── .env                 # Environment vars
    └── .env.example         # Template
```

---

## 🚀 Next Steps After Installation

### 1. Configure Database

Import NBA data schema:

```sql
-- Run in Supabase SQL Editor
-- See: /supabase/migrations/*.sql
```

### 2. Customize Settings

Edit `.env` for your preferences:

```env
VITE_APP_TIMEZONE=America/Chicago     # Your timezone
VITE_REFRESH_INTERVAL=30000           # Update frequency
```

### 3. Access Application

- **Dashboard**: <http://localhost:5173>
- **API Docs**: <http://localhost:8000/docs>
- **Health Check**: <http://localhost:8000/health>

### 4. Set Up Monitoring

Optional: Configure system monitoring for production

---

## 📖 Additional Resources

### Documentation

- **Main README**: [README.md](README.md) - Complete project overview
- **Windows Guide**: [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md) - Windows-specific setup
- **Pi Guide**: [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) - Raspberry Pi deployment
- **Troubleshooting**: [TROUBLESHOOTING_VENV.md](TROUBLESHOOTING_VENV.md) - Python environment issues

### Support

1. Check documentation first
2. Verify system requirements
3. Test with minimal configuration
4. Check logs for specific errors

---

## 🏀 Ready to Analyze NBA Data! 🚀
