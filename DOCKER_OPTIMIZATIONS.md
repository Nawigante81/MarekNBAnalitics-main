# Docker Optimizations

## Implemented Optimizations

### 1. Dockerignore Files
- **Root `.dockerignore`**: Excludes node_modules, build artifacts, IDE files, logs
- **Backend `.dockerignore`**: Excludes Python cache files, virtual environments, test files

### 2. Layer Caching Optimization
- **Package files copied first**: `package*.json` and `requirements.txt` copied before source code
- **Separate dependency installation**: Dependencies installed before copying source code
- **Multi-stage builds**: Clean separation between build and runtime stages

### 3. Security Enhancements
- **Non-root users**: Both frontend and backend run as non-privileged users
- **Non-privileged ports**: Frontend uses port 8080 instead of 80
- **Security headers**: Comprehensive security headers in Nginx configuration
- **Proper file permissions**: Correct ownership and permissions for all files

### 4. Performance Improvements
- **Nginx optimizations**: Gzip compression, static file caching, rate limiting
- **Python optimizations**: No cache pip installs, optimized dependency resolution
- **Node.js optimizations**: Silent installs, no audit/fund checks during CI

### 5. Build Command Optimizations
- **npm ci**: Used instead of npm install for faster, reproducible builds
- **pip optimizations**: Upgraded pip/setuptools/wheel, optimized dependency resolution
- **Debian non-interactive**: Prevents interactive prompts during apt installs

## Usage

### Quick Start
```bash
# Build and run all services
docker compose up --build

# Build without cache (for testing optimizations)
docker compose build --no-cache

# Run in detached mode
docker compose up -d
```

### Development
```bash
# Build specific service
docker compose build frontend
docker compose build backend

# View logs
docker compose logs -f frontend
docker compose logs -f backend

# Stop all services
docker compose down
```

### Production
```bash
# Build for production with optimizations
docker compose -f docker-compose.yml build

# Run with resource limits
docker compose up -d --scale backend=2
```

## Port Configuration
- **Frontend**: http://localhost:8080
- **Backend**: http://localhost:8000
- **Redis**: localhost:6379

## Security Features
- All services run as non-root users
- Frontend uses non-privileged port 8080
- Security headers enabled (XSS protection, frame options, etc.)
- Content Security Policy configured
- Rate limiting on API endpoints

## Performance Features
- Static file caching (1 year for JS/CSS, 30 days for images)
- Gzip compression enabled
- Optimized Nginx configuration
- Layer caching for faster rebuilds
- Multi-stage builds for smaller images