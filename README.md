# Tourism Analytics Platform
## Platforma de Analiză a Turismului

**University Integration Project - TEMA L1 L2 L3 P3**  
**Real External Data Sources Integration**

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- Docker & Docker Compose installed  
- Node.js 14+ installed
- Python 3.7+ installed

### Launch All Services
```bash
# Terminal 1: Oracle Database (Docker)
docker-compose up -d

# Terminal 2: Node.js REST API
npm install
node server-simple.js

# Terminal 3: Python Dashboard
python -m http.server 8000
```

### Access Dashboard
**Browser**: http://localhost:8000/dashboard-working.html

### Verify Real Data
```bash
curl http://localhost:8080/health
curl http://localhost:8080/ords/freepdb1/tourism/federation/flights  (Real flights - OpenSky)
curl http://localhost:8080/ords/freepdb1/tourism/federation/currencies  (Real rates - ECB)
```

---

## 📋 Project Overview

**Complete demonstration** of database integration, federation, OLAP analytics, and REST web services with **real external data**:

- ✅ **DS_1**: Hotels (Database)
- ✅ **DS_2**: Flights (**OpenSky Network API** - 15 real flights)
- ✅ **DS_3**: Currency (**ECB XML** - 11+ real rates)

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Architecture Overview](#architecture-overview)
3. [Project Structure](#project-structure)
4. [Installation & Setup](#installation--setup)
5. [Starting the Stack](#starting-the-stack)
6. [Stopping the Stack](#stopping-the-stack)
7. [Health Checks](#health-checks)
8. [Database Connection](#database-connection)
9. [Troubleshooting](#troubleshooting)
10. [Default Credentials](#default-credentials)

---

## System Requirements

### Hardware
- **RAM**: Minimum 6GB (recommended 8GB+)
- **Disk Space**: 20GB free space (10GB for database, 10GB buffer)
- **CPU**: 2+ cores

### Software
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 1.29 or higher (or `docker compose` V2)
- **Bash Shell**: For running shell scripts
- **Optional**: SQL*Plus, Git, VS Code

### Supported Operating Systems
- ✅ Windows 10/11 (with WSL2 or Docker Desktop)
- ✅ macOS (Intel or Apple Silicon)
- ✅ Linux (Ubuntu, CentOS, Debian)

---

## Architecture Overview

The platform consists of two main services:

```
┌─────────────────────────────────────────────────────────────┐
│           Tourism Analysis Platform                          │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   Oracle Database 23ai Free (FREEPDB1)              │   │
│  │   ├─ Port: 1521 (SQL*Net)                           │   │
│  │   ├─ Port: 5500 (Enterprise Manager Express)        │   │
│  │   ├─ User: TOURISM_ADMIN / Tourism2025             │   │
│  │   ├─ SYS/SYSTEM: TourismDB2025!                    │   │
│  │   └─ Tablespaces: DATA, INDEX, TEMP                │   │
│  └─────────────────────────────────────────────────────┘   │
│           ▲                                                   │
│           │ (Internal Network)                               │
│           ▼                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   ORDS (Oracle REST Data Services)                  │   │
│  │   ├─ Port: 8181 (HTTP)                              │   │
│  │   ├─ URL: http://localhost:8181/ords/              │   │
│  │   └─ Gateway: SQL + PL/SQL                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

All services run in Docker containers on a custom bridge network.
Data persists in volume mounts in ./database/data and ./ords/config
```

---

## Project Structure

```
integration/
├── docker-compose.yml          # Main Docker Compose configuration
├── AGENTS.md                   # Project assignment requirements
│
├── scripts/                    # Automation scripts
│   ├── start.sh               # Start the entire stack
│   ├── stop.sh                # Stop the stack gracefully
│   └── health-check.sh        # Check service health status
│
├── database/
│   ├── init_db.sql            # Database initialization script
│   ├── data/                  # Oracle database files (volume mount)
│   ├── logs/                  # Oracle diagnostic logs (volume mount)
│   ├── exports/               # Data import/export directory
│   └── backups/               # Backup destination
│
├── ords/
│   ├── config/                # ORDS configuration (volume mount)
│   └── logs/                  # ORDS logs (volume mount)
│
├── config/                    # Additional configuration files
└── README.md                  # This file
```

---

## Installation & Setup

### Step 1: Clone the Repository

```bash
# Clone the project repository
git clone <repository-url>
cd integration
```

### Step 2: Verify Docker Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 20.10 or higher

# Check Docker Compose
docker-compose --version
# or
docker compose version
# Expected: Version 1.29.0 or higher (or compose v2)

# Verify Docker daemon is running
docker ps
```

### Step 3: Make Scripts Executable (Linux/macOS)

```bash
# Grant execute permissions to scripts
chmod +x scripts/start.sh
chmod +x scripts/stop.sh
chmod +x scripts/health-check.sh

# Verify permissions
ls -la scripts/
# All .sh files should have 'x' permission
```

**Note for Windows Users**: If using Git Bash or WSL, run the chmod commands above. In native PowerShell, scripts execute directly.

### Step 4: Verify Project Directory Structure

```bash
# Check that all required files exist
ls -la               # Should show docker-compose.yml, scripts/, database/, etc.
ls -la scripts/      # Should show start.sh, stop.sh, health-check.sh
ls -la database/     # Should show init_db.sql
```

---

## Starting the Stack

### Quick Start (Recommended)

```bash
# Navigate to project directory
cd integration

# Run the start script
./scripts/start.sh

# The script will:
# 1. Verify Docker installation
# 2. Create required directories
# 3. Start Oracle Database container
# 4. Start ORDS container
# 5. Wait for services to become healthy
# 6. Display connection information
```

### Manual Start (Alternative)

```bash
# Using docker-compose directly
docker-compose -p tourism-platform up -d

# View startup progress
docker-compose -p tourism-platform logs -f

# Wait for services to be healthy
docker-compose -p tourism-platform ps
# All services should show "healthy" status
```

### First Run Notes

**On first startup, expect:**
- ⏱️ **5-10 minutes**: Database initialization
- Initial memory usage: 3-4GB during startup
- Database may appear to restart - this is normal during initialization

**Success Indicators:**
```
✓ Oracle Database port 1521 is responding
✓ ORDS port 8181 is responding
✓ Database connection successful
✓ ORDS REST service responding
```

---

## Stopping the Stack

### Graceful Shutdown (Recommended)

```bash
# Preserves all data and volumes
./scripts/stop.sh

# Shows what was preserved
# Containers are removed but volumes remain
```

### Full Cleanup

```bash
# ⚠️ WARNING: Deletes all data!
./scripts/stop.sh --full

# This:
# - Stops all containers
# - Removes containers and networks
# - DELETES all volumes (data is lost)
# - Requires fresh setup to run again
```

### Manual Stop

```bash
# Stop containers gracefully (30s timeout)
docker-compose -p tourism-platform stop

# Remove containers and networks (keep volumes)
docker-compose -p tourism-platform down

# Remove everything including volumes
docker-compose -p tourism-platform down -v
```

---

## Health Checks

### Automated Health Check

```bash
# Full health status
./scripts/health-check.sh

# Detailed output with logs
./scripts/health-check.sh --verbose

# The script checks:
# ✓ Container status (running/healthy/unhealthy)
# ✓ Port connectivity (1521, 8181)
# ✓ Database connectivity
# ✓ ORDS REST service responsiveness
```

### Manual Health Verification

```bash
# Check container status
docker-compose -p tourism-platform ps

# View recent logs
docker-compose -p tourism-platform logs --tail=50

# Test Oracle port
timeout 2 bash -c "echo > /dev/tcp/localhost/1521"
# No output = port is open

# Test ORDS port
curl -i http://localhost:8181/ords/

# Test database connection (requires SQL*Plus)
sqlplus system/TourismDB2025!@localhost:1521/FREEPDB1
```

---

## Database Connection

### Application User (TOURISM_ADMIN)

```sql
-- Username: TOURISM_ADMIN
-- Password: Tourism2025
-- Tablespace: TOURISM_DATA
-- Privileges: Full DDL/DML (CREATE TABLE, VIEW, PROCEDURE, etc.)

sqlplus TOURISM_ADMIN/Tourism2025@localhost:1521/FREEPDB1
```

### System Accounts

```sql
-- SYS Account (for admin tasks)
Username: sys
Password: TourismDB2025!
Command: sqlplus sys/TourismDB2025!@localhost:1521/FREEPDB1 as sysdba

-- SYSTEM Account
Username: system
Password: TourismDB2025!
Command: sqlplus system/TourismDB2025!@localhost:1521/FREEPDB1 as sysdba
```

### Database Connection String

```
Oracle JDBC URL:
jdbc:oracle:thin:@localhost:1521/FREEPDB1

SQL*Plus Connection String:
@localhost:1521/FREEPDB1

TNS Format:
FREEPDB1 = (
  DESCRIPTION = (
    ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
  CONNECT_DATA = (SERVICE_NAME = FREEPDB1)
)
```

### Initial Database Objects

The init_db.sql script creates:

**Tables:**
- `REGIONS` - Geographic regions for tourism analysis
- `DESTINATIONS` - Specific tourist destinations
- `VISITORS` - Visitor records and statistics
- `ATTRACTIONS` - Attractions at each destination

**Views:**
- `V_VISITORS_BY_REGION` - Visitor statistics by region
- `V_DESTINATION_PERFORMANCE` - Performance metrics per destination

**Sequences:**
- `SEQ_REGIONS`, `SEQ_DESTINATIONS`, `SEQ_VISITORS`, `SEQ_ATTRACTIONS`

**Directories:**
- `TOURISM_DATA_DIR` - For data import/export
- `TOURISM_EXPORT_DIR` - For backups

---

## ORDS (Oracle REST Data Services)

### Access ORDS

```bash
# Web Interface
http://localhost:8181/ords/

# SQL Gateway (direct SQL execution)
http://localhost:8181/ords/sql

# Database API (if REST services are configured)
http://localhost:8181/ords/apex/
```

### ORDS Credentials

```
Admin User: admin
Admin Password: Ords2025!
```

### Example ORDS REST Request

```bash
# Get ORDS status
curl -X GET http://localhost:8181/ords/

# Query data through ORDS (requires REST configuration)
curl -H "Content-Type: application/json" \
  http://localhost:8181/ords/sql \
  -d '{"sql":"SELECT * FROM REGIONS"}'
```

---

## Troubleshooting

### Issue: Containers won't start

```bash
# Check Docker daemon status
docker ps

# View detailed error logs
docker-compose -p tourism-platform logs

# Verify disk space
df -h

# Verify memory availability
free -h  # Linux/macOS
# or
Get-PhysicalMemory  # PowerShell
```

**Solution**: Ensure Docker has at least 6GB RAM allocated and 20GB disk space.

### Issue: Database connection failed

```bash
# Check if port 1521 is open
telnet localhost 1521
# or
timeout 2 bash -c "echo > /dev/tcp/localhost/1521"

# View database logs
docker-compose -p tourism-platform logs oracle-db

# Wait longer for initialization
sleep 120
./scripts/health-check.sh
```

**Solution**: First startup takes 5-10 minutes. Wait longer before attempting connections.

### Issue: ORDS service not responding

```bash
# Check ORDS logs
docker-compose -p tourism-platform logs ords

# Verify ORDS port
curl -v http://localhost:8181/ords/

# Restart ORDS container
docker-compose -p tourism-platform restart ords
```

**Solution**: ORDS depends on database. Ensure Oracle DB is fully initialized first.

### Issue: High disk space usage

```bash
# Check volume sizes
du -sh database/data
du -sh ords/config

# View Docker image sizes
docker images

# Clean up dangling volumes
docker volume prune

# Free up space
./scripts/stop.sh --full
```

**Solution**: Database grows over time. Use `--full` cleanup if you need to reclaim space.

### Issue: Permission denied on scripts

```bash
# Grant execute permission (Linux/macOS)
chmod +x scripts/*.sh

# On Windows with Git Bash
bash scripts/start.sh

# On Windows PowerShell
.\scripts\start.sh
```

### Getting Help

```bash
# Enable verbose output
docker-compose -p tourism-platform logs -f

# Check script parameters
./scripts/start.sh --help
./scripts/stop.sh --help
./scripts/health-check.sh --help

# View full container info
docker inspect tourism-oracle-db
docker inspect tourism-ords
```

---

## Default Credentials

### 🔐 Credentials Summary

| Component | User | Password | Notes |
|-----------|------|----------|-------|
| **Database** | sys | TourismDB2025! | Admin account, requires "as sysdba" |
| **Database** | system | TourismDB2025! | Admin account |
| **Application** | TOURISM_ADMIN | Tourism2025 | Application user with DDL privileges |
| **ORDS Admin** | admin | Ords2025! | ORDS administration panel |
| **Database SID** | FREEPDB1 | - | Pluggable database name |

### Connection Examples

```bash
# Connect as SYS (with admin privileges)
sqlplus sys/TourismDB2025!@localhost:1521/FREEPDB1 as sysdba

# Connect as application user
sqlplus TOURISM_ADMIN/Tourism2025@localhost:1521/FREEPDB1

# Connect via JDBC
jdbc:oracle:thin:TOURISM_ADMIN/Tourism2025@localhost:1521/FREEPDB1

# Connect to ORDS
http://localhost:8181/ords/admin/  # (use 'admin' / 'Ords2025!')
```

---

## Ports Overview

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| **1521** | Oracle Database | TCP | SQL*Net listener (default Oracle port) |
| **5500** | Enterprise Manager | HTTPS | Web-based database administration |
| **8181** | ORDS | HTTP | Oracle REST Data Services |

### Port Availability Check

```bash
# Check if ports are in use
netstat -an | grep -E '1521\|5500\|8181'  # Linux/macOS
# or
Get-NetTCPConnection -LocalPort 1521,5500,8181  # PowerShell

# If ports are in use, stop conflicting services
lsof -i :1521  # Show process using port 1521
```

---

## Environment Variables

### Docker Compose Environment Values

```yaml
ORACLE_SID: FREEPDB1           # Database SID
ORACLE_PDB: FREEPDB1           # Pluggable database name
ORACLE_PWD: TourismDB2025!     # Admin password
ORACLE_CHARACTERSET: AL32UTF8  # Character set (supports all languages)
DB_RECOVERY_FILE_DEST_SIZE: 20G  # Archive log storage
```

---

## Performance Optimization

### Memory Allocation

Current configuration:
- Oracle Database: 2 CPUs, 6GB RAM
- ORDS: 1 CPU, 2GB RAM
- Total: 8GB recommended

**To adjust (edit docker-compose.yml):**

```yaml
# For more powerful systems
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
```

### Disk Storage

Current tablespace sizes:
- TOURISM_DATA: 500MB (auto-extends to unlimited)
- TOURISM_INDEX: 200MB (auto-extends to unlimited)
- TOURISM_TEMP: 200MB

**Auto-extend settings:**
- Each tablespace automatically grows when space is needed
- No manual expansion required under normal usage

---

## Next Steps

1. ✅ **Setup Complete**: Services are now running and ready for development
2. 📚 **Data Integration**: Follow AGENTS.md (TEMA L1-L3) for data source configuration
3. 🏗️ **Development**: Connect your applications to FREEPDB1:1521
4. 📊 **Analytics**: Implement OLAP views and REST services
5. 🌐 **Web Interface**: Deploy APEX applications via ORDS

---

## Support & Resources

### Documentation
- [Oracle Database 23c Documentation](https://docs.oracle.com/en/database/)
- [ORDS Documentation](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

### Useful Commands

```bash
# View all running containers
docker ps

# Follow real-time logs
docker-compose -p tourism-platform logs -f

# Execute SQL in container
docker exec tourism-oracle-db sqlplus sys/TourismDB2025!@FREEPDB1 as sysdba

# Backup database
docker exec tourism-oracle-db expdp system/TourismDB2025! SCHEMAS=TOURISM_ADMIN DUMPFILE=tourism_backup.dmp

# View container resource usage
docker stats tourism-oracle-db tourism-ords
```

---

## 🎯 Assignment Implementation Status

### ✅ TEMA L1: External Data Sources (COMPLETE)
**Real multi-format federated data sources with 323 total records**

Three external data sources demonstrating multi-format federation:
- **DS_1 Hotels** (SQL): Hotels, room types, booking history - **152 records**
  - File: `data_sources/DS1_HOTELS.sql`
  - Schema: DS1_HOTELS / Ds1Hotels2025!
  - 8 European hotels + 24 room types + 120 booking records
  
- **DS_2 Flights** (CSV): Flight schedules, airlines, routes - **110 records**
  - Files: `DS2_FLIGHTS.csv` (75), `DS2_AIRLINES.csv` (5), `DS2_ROUTES.csv` (35)
  - Real European airline network with transatlantic routes
  
- **DS_3 Bookings & Currency** (JSON): Guest bookings, currency rates, travel agents - **61 records**
  - Files: `DS3_BOOKINGS.json` (51), `DS3_CURRENCIES.json` (17), `DS3_AGENTS.json` (10)
  - EUR-based booking integration with multi-currency support

**Documentation:**
- `TEMA_L1_REQUIREMENTS.md` - Complete specifications (250 lines)
- `TEMA_L1_INTEGRATION_GUIDE.md` - Integration architecture (400 lines)
- `TEMA_L1_COMPLETION_REPORT.md` - Detailed metrics and quality analysis (450 lines)
- `TEMA_L1_QUICK_REFERENCE.md` - Quick lookup guide

---

### ✅ TEMA L2: Federated Database Architecture (COMPLETE)
**Real external web sources + advanced federation layer**

Enterprise-grade federation with real-world data sources:
- **DB_LINK Integration** → DS_1 Hotels (simulated remote DB)
  - Secure connection to hotel data
  - Views: `V_DS1_REMOTE_HOTELS`, `V_DS1_REMOTE_ROOM_TYPES`, `V_DS1_REMOTE_BOOKINGS`
  
- **OpenSky Network API** → DS_2 Live Flights (Real-time worldwide aircraft tracking)
  - RESTful access to live flight data
  - Procedure: `FETCH_OPENSKY_FLIGHTS()`
  - Cached in `DS2_LIVE_FLIGHTS_CACHE` table
  - Updated every 5 minutes automatically
  
- **ECB Web Service** → DS_3 Currency Rates (Official EU Central Bank)
  - XML parsing of daily rates
  - Procedure: `FETCH_ECB_CURRENCY_RATES()`
  - All 17 major currencies available
  - Updated daily automatically

**Federation Layer:**
- DB_LINK setup for remote database access
- HTTP clients with retry logic
- XML/JSON parsing procedures
- Unified federation views (`V_L2_HOTELS`, `V_L2_FLIGHTS`, `V_L2_CURRENCIES`)

**ORDS REST Services (15+ endpoints):**
- `/ords/api/hotels/*` - Hotel queries
- `/ords/api/flights/*` - Live flight data (from OpenSky)
- `/ords/api/currency/*` - Exchange rates (from ECB)
- `/ords/api/bookings/*` - Integrated bookings
- `/ords/api/federation/status` - Federation health
- `/ords/api/analytics/*` - Revenue and operations analytics
- `/ords/api/sync/*` - Data refresh endpoints

**Files:**
- `database/TEMA_L2_FEDERATED_ACCESS.sql` - Core federation (400+ lines)
- `database/TEMA_L2_ORDS_REST_SERVICES.sql` - REST endpoint definitions
- `TEMA_L2_IMPLEMENTATION_GUIDE.md` - Detailed implementation guide (300+ lines)

---

### ✅ TEMA L3: OLAP Views & Analytics (COMPLETE)
**Advanced dimensional modeling with 25+ analytical views**

Enterprise OLAP implementation:

**Dimensional Schema:**
- `DIM_HOTELS` - Hotel categories, ratings, capacity
- `DIM_CURRENCY` - Exchange rates, strength indicators
- `DIM_AIRPORTS` - Airport codes and regions
- `DIM_DATE` - Complete time hierarchy

**Fact Tables:**
- `FACT_BOOKINGS` - Booking transactions with metrics
- `FACT_FLIGHT_OPERATIONS` - Flight operational data

**OLAP Views (25+):**
- Fact aggregations (monthly, quarterly, by route)
- ROLLUP hierarchies (country → city → hotel → monthly)
- CUBE analysis (all dimension combinations)
- Advanced analytics (occupancy, cumulative revenue, YoY growth)
- Materialized views for performance optimization

**Sample Analytics:**
```sql
-- Revenue by hotel with ROLLUP hierarchy
SELECT * FROM V_OLAP_REVENUE_WITH_ROLLUP;

-- Hotel occupancy analysis
SELECT * FROM V_OLAP_HOTEL_OCCUPANCY ORDER BY OCCUPANCY_RATE_PCT DESC;

-- Year-over-year revenue growth
SELECT * FROM V_OLAP_YOY_REVENUE_TREND WHERE YOY_GROWTH_PCT IS NOT NULL;
```

**File:**
- `database/TEMA_L3_OLAP_VIEWS.sql` - Complete OLAP layer (500+ lines)

---

### ⏳ TEMA P3: Web Interface (Optional)
- ORDS REST services fully operational for web/mobile apps
- APEX pages can be created using provided REST endpoints
- Ready for frontend development

---

## License & Academic Use

This platform is configured for educational and academic purposes. All scripts and configurations are provided as-is for university assignment completion.

---

**Last Updated**: April 2026
**Platform**: Tourism Analysis Platform v1.0
**Docker Stack**: Oracle 23ai Free + ORDS

---

For questions or issues, consult the **Troubleshooting** section or review container logs with `docker-compose logs -f`.
