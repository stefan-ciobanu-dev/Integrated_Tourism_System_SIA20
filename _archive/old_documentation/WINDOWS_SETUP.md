# Tourism Analysis Platform - WINDOWS SETUP GUIDE
# Windows-Specific Instructions

## 🪟 Windows Setup Instructions

This guide covers setup for Windows 10/11 (both native Docker and WSL2).

---

## Prerequisites Check (Windows)

### 1. Install Docker Desktop

**For Windows 10/11 Pro/Enterprise (Recommended with WSL2)**:
```
1. Download: https://www.docker.com/products/docker-desktop
2. Install the installer
3. During installation: CHECK "Install required WSL2 kernel update"
4. Restart computer when prompted
5. Open Powershell (Admin) and verify:
   docker --version
   docker run hello-world
```

**For Windows 10 Home Edition**:
```
1. Install Windows Subsystem for Linux 2 (WSL2):
   - Open PowerShell (Admin)
   - Run: wsl --install
   - Choose Ubuntu from Microsoft Store
   - Restart computer
   
2. Install Docker Desktop with WSL2 backend (see Pro/Enterprise steps above)
```

### 2. Verify Installation

Open **PowerShell** or **Windows Terminal** and run:

```powershell
# Check Docker
docker --version
# Expected: Docker version 20.10 or higher

# Check Docker Compose
docker-compose --version
# or
docker compose version
# Expected: docker-compose version 1.29 or higher

# Verify Docker daemon
docker ps
# Should show "CONTAINER ID, IMAGE, COMMAND..." (even if empty)
```

If commands fail, Docker is not properly installed.

---

## Project Setup (Windows)

### Method 1: Using PowerShell (Recommended)

```powershell
# 1. Navigate to project folder
cd D:\Repositories\integration

# 2. Verify files exist
dir

# 3. View the start script
type .\scripts\start.sh

# 4. Run the start script
.\scripts\start.sh
```

### Method 2: Using Git Bash (If Installed)

```bash
# Navigate to project
cd /d/Repositories/integration

# Run script same as Linux
./scripts/start.sh
```

### Method 3: Using Windows Command Prompt

```cmd
:: Navigate to project
cd D:\Repositories\integration

:: View available scripts
dir scripts\

:: Run start script from PowerShell instead
powershell -NoExit -Command ".\scripts\start.sh"
```

---

## Starting the Stack (Windows)

### Option A: PowerShell Script (Preferred)

```powershell
# 1. Open PowerShell (regular user, not admin required)
# 2. Navigate to project:
cd D:\Repositories\integration

# 3. Run start script:
.\scripts\start.sh

# Script will:
# ✓ Check Docker installation
# ✓ Create required directories
# ✓ Start containers
# ✓ Wait for services (2-3 min)
# ✓ Display connection info when ready

# Output will show:
# [SUCCESS] All services are healthy!
# [SUCCESS] Platform ready to use!
```

### Option B: Using Docker Compose Directly

```powershell
# Create required directories first
mkdir database\data, database\logs, database\exports, ords\config, ords\logs -Force

# Start services
docker-compose -p tourism-platform up -d

# Wait and monitor
docker-compose -p tourism-platform logs -f

# Check status
docker-compose -p tourism-platform ps
```

### Option C: Hybrid Approach (Manual + Script)

```powershell
# Create directories
mkdir database\data, database\logs, database\exports, ords\config, ords\logs -Force

# Start containers
docker-compose -p tourism-platform up -d

# Wait for services to become healthy
Start-Sleep -Seconds 120

# Run health check
.\scripts\health-check.sh
```

---

## Monitoring Startup (Windows)

### Using PowerShell

```powershell
# Run start script with real-time output
.\scripts\start.sh

# Or watch logs in real-time
docker-compose -p tourism-platform logs -f

# Check individual service logs
docker-compose -p tourism-platform logs -f oracle-db
docker-compose -p tourism-platform logs -f ords

# Check container status
docker-compose -p tourism-platform ps

# View specific container info
docker inspect tourism-oracle-db
```

### Expected Startup Timeline

```
T+0s:   Starting Docker Compose stack...
T+5s:   Oracle container initializes
T+30s:  Oracle starts database (first startup)
T+60s:  ORDS container starts (depends on Oracle)
T+120s: Oracle initialization completes
T+150s: All services becoming healthy
T+180s: All services healthy, ready to use ✓
```

---

## Stopping the Stack (Windows)

### Using PowerShell Script

```powershell
# Graceful stop - preserves data
.\scripts\stop.sh

# Full stop - DELETES all data (be careful!)
.\scripts\stop.sh --full

# Manually verify stopped
docker-compose -p tourism-platform ps
# Should show nothing or "Down"
```

### Manual Stop

```powershell
# Stop containers (30-second graceful timeout)
docker-compose -p tourism-platform stop

# Remove containers and networks (keep data)
docker-compose -p tourism-platform down

# Remove everything including data volumes
docker-compose -p tourism-platform down -v
```

---

## Health Checks (Windows)

### Using Health Check Script

```powershell
# Run health check
.\scripts\health-check.sh

# Verbose output with logs
.\scripts\health-check.sh --verbose

# Shows:
# ✓ Container status
# ✓ Port connectivity (1521, 8181)
# ✓ Database connection
# ✓ ORDS REST service
```

### Manual Tests

```powershell
# Test Docker connectivity
docker ps

# Test Oracle port (must be open)
$TCPConnection = @{
    ComputerName = 'localhost'
    Port = 1521
    ErrorAction = 'SilentlyContinue'
}
if (Test-NetConnection @TCPConnection | Select-Object -ExpandProperty TcpTestSucceeded) {
    Write-Host "✓ Oracle port 1521 is open"
} else {
    Write-Host "✗ Oracle port 1521 is CLOSED"
}

# Test ORDS port
$TCPConnection.Port = 8181
if (Test-NetConnection @TCPConnection | Select-Object -ExpandProperty TcpTestSucceeded) {
    Write-Host "✓ ORDS port 8181 is open"
}

# Test ORDS with curl
curl -i http://localhost:8181/ords/
```

---

## Database Connection (Windows)

### Connection String for Windows

```
Database: localhost:1521/FREEPDB1
User: TOURISM_ADMIN
Password: Tourism2025
Admin: system / TourismDB2025!
```

### Using SQL*Plus (If Installed)

```powershell
# Open Command Prompt or PowerShell
sqlplus TOURISM_ADMIN/Tourism2025@localhost:1521/FREEPDB1

# You should see:
# SQL>

# Test connection:
# SQL> SELECT * FROM REGIONS;
# SQL> EXIT;
```

### Using SQL Developer (Free IDE)

```
1. Download: https://www.oracle.com/database/sqldeveloper/
2. Install and open
3. Create new connection:
   - Connection Name: Tourism_Platform
   - Username: TOURISM_ADMIN
   - Password: Tourism2025
   - Hostname: localhost
   - Port: 1521
   - Service Name: FREEPDB1
4. Click "Test" button
5. If successful, click "Save"
```

### Using OnlineQuery Tool (No Installation)

```
1. Open browser to: https://www.oraclecloud.com/
2. Use Database Tools -> SQL Worksheets (for cloud DB)
3. Or for local connection, configure port forwarding
```

---

## ORDS Web Access (Windows)

### Open ORDS in Browser

```
1. Open your web browser
2. Enter URL: http://localhost:8181/ords/
3. You should see ORDS welcome page

4. Admin panel: http://localhost:8181/ords/admin/
   - Username: admin
   - Password: Ords2025!
```

### Test REST Endpoint

```powershell
# Using curl in PowerShell
curl http://localhost:8181/ords/

# Using Invoke-WebRequest (PowerShell native)
Invoke-WebRequest -Uri http://localhost:8181/ords/ -Method GET

# Using Postman (download from https://www.postman.com/downloads/)
1. Create new GET request
2. URL: http://localhost:8181/ords/
3. Click Send
4. Should see ORDS response
```

---

## Resource Allocation (Windows)

### Docker Desktop Settings

**For Windows 10/11 with Docker Desktop**:

```
1. Right-click Docker icon in system tray
2. Select "Settings" or "Preferences"
3. Go to "Resources"
4. Set memory: Minimum 6GB, Recommended 8GB
5. Set CPU: Minimum 2 cores, Recommended 4 cores
6. Set Disk image size: 40GB
7. Click "Apply & Restart"
```

### Check Current Allocation

```powershell
# Check Docker system info
docker system info | Select-String -Pattern "Memory|CPUs|Docker Root Dir"

# View current usage
docker stats `
  --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}"
```

---

## Troubleshooting (Windows-Specific)

### Issue: "Docker daemon is not running"

```powershell
# Solution 1: Start Docker Desktop
# - Open Docker Desktop from Start Menu
# - Wait 30 seconds for daemon to start
# - Verify: docker ps

# Solution 2: Restart Docker
# - Right-click Docker icon → Quit Docker Desktop
# - Wait 10 seconds
# - Click Docker icon again to start
# - Verify: docker ps
```

### Issue: "Cannot connect to Docker daemon"

```powershell
# Solution 1: Check Docker installation
where docker
# Should show: C:\Program Files\Docker\Docker\resources\bin\docker.exe

# Solution 2: Check if running as admin
# - Open PowerShell as Administrator
# - Run: docker ps

# Solution 3: Reset Docker
# - Open Docker Desktop
# - Settings → General → "Troubleshoot"
# - Click "Restart Docker" button
```

### Issue: "Port 1521 already in use"

```powershell
# Find what's using the port
Get-NetTCPConnection -LocalPort 1521

# If it's a previous Docker container:
docker-compose -p tourism-platform down
docker container prune

# Try different port (edit docker-compose.yml):
# Change: ports: - "1521:1521"
# To:     ports: - "1522:1521"
# Then use 1522 in connection strings
```

### Issue: "Insufficient disk space"

```powershell
# Check available disk space
Get-Volume | Select-Object DriveLetter, Size, SizeRemaining, @{
    Name="PercentFree"
    Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100, 1)}
}

# Need at least 20GB free for:
# - Docker images (~5GB)
# - Oracle database files (~10GB)
# - Working space (~5GB)

# If low on space:
# Solution: Delete old Docker images/containers
docker image prune -a
docker system prune --volumes

# Or: Clean up old project volumes
docker volume ls
docker volume rm VOLUME_NAME
```

### Issue: "Out of memory during startup"

```powershell
# Increase Docker memory allocation
# 1. Settings → Resources → Memory
# 2. Set to minimum 6GB (8GB recommended)
# 3. Click Apply & Restart

# Monitor during startup
docker stats tourism-oracle-db --no-stream
```

### Issue: "Containers fail to start"

```powershell
# Check detailed error logs
docker-compose -p tourism-platform logs

# Check specific service
docker logs tourism-oracle-db

# Restart in debug mode
docker-compose -p tourism-platform up --no-detach

# This shows real-time output instead of background
```

---

## File Paths (Windows Specifics)

### Docker-Compose Volume Mounts

```yaml
# Windows Docker paths (relative to project root)
./database/data       → C:\Users\YourUser\... \integration\database\data
./database/logs       → C:\Users\YourUser\... \integration\database\logs
./database/exports    → C:\Users\YourUser\... \integration\database\exports
./ords/config         → C:\Users\YourUser\... \integration\ords\config
./ords/logs           → C:\Users\YourUser\... \integration\ords\logs
```

### Check Windows Volume Mounts

```powershell
# List all Docker volumes
docker volume ls

# Inspect specific volume
docker volume inspect VOLUME_NAME

# View volume location
# Typically: C:\Users\USERNAME\AppData\Local\Docker\wsl\data\mnt\wsl\...
```

---

## Terminal Recommendations (Windows)

### Windows Terminal (Recommended)
```
1. Download from Microsoft Store: "Windows Terminal"
2. Click Windows icon, type "terminal"
3. Features: tabs, themes, customization
4. Works with PowerShell, cmd, git bash
```

### PowerShell (Built-in)
```
1. Right-click Start button → PowerShell
2. Type: powershell -NoProfile
3. Modern, scripting-friendly
4. Recommended for automation scripts
```

### Git Bash (If Git is Installed)
```
1. Right-click in folder → "Git Bash Here"
2. Use same commands as Linux
3. Recommended for consistency with Unix users
4. Download from: https://git-scm.com/
```

### Command Prompt (Legacy)
```
1. Press Win+R, type "cmd", press Enter
2. Works for basic commands
3. Limited shell features
4. Not recommended for advanced usage
```

---

## Performance Tips (Windows)

### Optimize Docker Performance
```powershell
# 1. Allocate sufficient resources
#    Settings: Memory 6-8GB, CPU 2-4 cores

# 2. Store files on local drive
#    Don't use network shares (slow!)

# 3. Use WSL2 backend (not Hyper-V)
#    Check Docker Settings → General

# 4. Close unnecessary applications
#    Reduces memory pressure during startup

# 5. Check Windows updates
#    Ensure WSL2 kernel is up to date
```

### Monitor System Resources
```powershell
# Real-time system stats
while ($true) {
    Clear-Host
    Get-Process | Where-Object {$_.ProcessName -match 'docker'} | 
        Select-Object Name, CPU, Memory | Sort-Object Memory -Desc
    Start-Sleep -Seconds 2
}

# Docker usage stats
docker stats `
  --no-stream `
  --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}"
```

---

## Quick Reference (Windows)

### Essential PowerShell Commands

```powershell
# Navigate project
Set-Location D:\Repositories\integration

# Start stack
.\scripts\start.sh

# Check status
.\scripts\health-check.sh

# Stop stack
.\scripts\stop.sh

# View logs
docker-compose -p tourism-platform logs -f

# Connect to database
docker exec -it tourism-oracle-db sqlplus TOURISM_ADMIN/Tourism2025

# List containers
docker ps

# List images
docker images

# Prune unused resources
docker system prune -a
```

---

## Next Steps

1. ✅ Install Docker Desktop
2. ✅ Run `.\scripts\start.sh`
3. ✅ Wait for startup (5-10 minutes)
4. ✅ Run `.\scripts\health-check.sh`
5. ✅ Connect to database using provided credentials
6. ✅ Proceed with TEMA L1 (Data Source Definition)

---

## Support Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker for Windows Guide**: https://docs.docker.com/docker-for-windows/
- **WSL2 Documentation**: https://docs.microsoft.com/en-us/windows/wsl/
- **PowerShell Documentation**: https://docs.microsoft.com/en-us/powershell/

---

**Platform**: Windows 10/11
**Created**: April 2026
**Status**: ✅ WINDOWS SETUP GUIDE COMPLETE

