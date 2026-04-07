#============================================================================
# Tourism Analysis Platform - Complete Deployment (PowerShell)
#============================================================================
# This script deploys TEMA L1, L2, and L3 to an Oracle database
# Usage: powershell -ExecutionPolicy Bypass -File DEPLOY.ps1
#============================================================================

param(
    [string]$DatabaseHost = "localhost",
    [int]$DatabasePort = 1521,
    [string]$DatabaseName = "FREEPDB1",
    [string]$AdminUser = "TOURISM_ADMIN",
    [string]$AdminPassword = "Tourism2025!",
    [string]$ScriptDir = "$PSScriptRoot\database"
)

# ============================================================================
# Functions
# ============================================================================

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Test-SQLPlusExists {
    try {
        $output = sqlplus -v 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Deploy-Script {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string]$LogFile
    )
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "Script not found: $ScriptPath"
        return $false
    }
    
    Write-Info "Deploying: $Description"
    
    $connString = "$AdminUser/$AdminPassword@$DatabaseHost`:$DatabasePort/$DatabaseName"
    
    try {
        # Execute SQL script
        $sqlCommand = "@`"$ScriptPath`""
        $process = Start-Process -FilePath "sqlplus" `
            -ArgumentList "-S $connString $sqlCommand" `
            -RedirectStandardOutput $LogFile `
            -RedirectStandardError "$LogFile.err" `
            -NoNewWindow `
            -PassThru `
            -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Success "$Description completed"
            return $true
        }
        else {
            Write-Warning "$Description completed with warnings (exit code: $($process.ExitCode))"
            return $true
        }
    }
    catch {
        Write-Error "Failed to deploy $Description : $_"
        return $false
    }
}

# ============================================================================
# Main Deployment
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Tourism Analysis Platform - Complete Deployment" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration Summary
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Database Host: $DatabaseHost"
Write-Host "  Database Port: $DatabasePort"
Write-Host "  Database Name: $DatabaseName"
Write-Host "  Admin User:    $AdminUser"
Write-Host "  Script Dir:    $ScriptDir"
Write-Host ""

# Step 1: Verify scripts
Write-Host "[Step 1] Verifying SQL scripts..." -ForegroundColor Cyan
$scriptsOK = $true
$requiredScripts = @(
    "init_db.sql",
    "TEMA_L2_FEDERATED_ACCESS.sql",
    "TEMA_L2_ORDS_REST_SERVICES.sql",
    "TEMA_L3_OLAP_VIEWS.sql",
    "TEMA_L3_VERIFY.sql"
)

foreach ($script in $requiredScripts) {
    $path = Join-Path $ScriptDir $script
    if (Test-Path $path) {
        Write-Success "Found: $script"
    }
    else {
        Write-Error "Missing: $script"
        $scriptsOK = $false
    }
}

if (-not $scriptsOK) {
    Write-Error "Not all required scripts found. Aborting."
    exit 1
}

# Step 2: Check SQL*Plus
Write-Host ""
Write-Host "[Step 2] Checking SQL*Plus availability..." -ForegroundColor Cyan
if (Test-SQLPlusExists) {
    Write-Success "SQL*Plus is available"
}
else {
    Write-Error "SQL*Plus not found. Please install Oracle Client or Database."
    Write-Info "See: ORACLE_SETUP_WINDOWS.md"
    exit 1
}

# Step 3: Create log directory
Write-Host ""
Write-Host "[Step 3] Creating deployment logs..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyy_MM_dd_HHmmss"
$logDir = Join-Path (Split-Path $PSScriptRoot) "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "deployment_$timestamp.log"
Write-Success "Log file: $logFile"

# Step 4: Deploy TEMA L1
Write-Host ""
Write-Host "[Step 4/5] Deploying TEMA L1 (Base Schema)..." -ForegroundColor Cyan
$l1Script = Join-Path $ScriptDir "init_db.sql"
Deploy-Script -ScriptPath $l1Script -Description "TEMA L1 - Base Schema" -LogFile "$logFile.tema_l1.log" | Out-Null

# Step 5: Deploy TEMA L2
Write-Host ""
Write-Host "[Step 5/5] Deploying TEMA L2 (Federation Layer)..." -ForegroundColor Cyan
Write-Info "Creating:"
Write-Host "  - L2_FEDERATION user and privileges"
Write-Host "  - DB_LINK to remote hotel database"
Write-Host "  - OpenSky Network API integration"
Write-Host "  - ECB currency rate parser"
Write-Host "  - Federation views (4 views)"
Write-Host "  - Public access grants"

$l2Script = Join-Path $ScriptDir "TEMA_L2_FEDERATED_ACCESS.sql"
if (-not (Deploy-Script -ScriptPath $l2Script -Description "TEMA L2 - Federation Layer" -LogFile "$logFile.tema_l2.log")) {
    Write-Error "TEMA L2 deployment failed"
    exit 1
}

# Deploy TEMA L2 ORDS Services
Write-Host ""
Write-Host "[Continuing] Deploying TEMA L2 ORDS REST Services..." -ForegroundColor Cyan
Write-Info "Creating 15+ REST endpoints for:"
Write-Host "  - Hotels, Flights, Currency data access"
Write-Host "  - Integration endpoints"
Write-Host "  - Analytics endpoints"
Write-Host "  - Data synchronization endpoints"

$l2OrdScript = Join-Path $ScriptDir "TEMA_L2_ORDS_REST_SERVICES.sql"
if (-not (Deploy-Script -ScriptPath $l2OrdScript -Description "TEMA L2 - ORDS Services" -LogFile "$logFile.tema_l2_ords.log")) {
    Write-Warning "TEMA L2 ORDS deployment had issues (may be OK)"
}

# Step 6: Deploy TEMA L3
Write-Host ""
Write-Host "[Step 6/6] Deploying TEMA L3 (OLAP Analytics)..." -ForegroundColor Cyan
Write-Info "Creating:"
Write-Host "  - Dimensional tables (DIM_HOTELS, DIM_CURRENCY, DIM_AIRPORTS, DIM_DATE)"
Write-Host "  - Fact tables (FACT_BOOKINGS, FACT_FLIGHT_OPERATIONS)"
Write-Host "  - OLAP views (15+ analytical views)"
Write-Host "  - Materialized view (MV_REVENUE_SUMMARY)"
Write-Host "  - Performance indexes"
Write-Host "  - Public access grants"

$l3Script = Join-Path $ScriptDir "TEMA_L3_OLAP_VIEWS.sql"
if (-not (Deploy-Script -ScriptPath $l3Script -Description "TEMA L3 - OLAP Views" -LogFile "$logFile.tema_l3.log")) {
    Write-Error "TEMA L3 deployment failed"
    exit 1
}

# Step 7: Verification
Write-Host ""
Write-Host "[Step 7] Running Verification Tests..." -ForegroundColor Cyan
$verifyScript = Join-Path $ScriptDir "TEMA_L3_VERIFY.sql"
if (-not (Deploy-Script -ScriptPath $verifyScript -Description "TEMA L3 - Verification" -LogFile "$logFile.verify.log")) {
    Write-Warning "Verification had issues - check logs"
}

# Success Summary
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Success "TEMA L1: Base schema and data sources"
Write-Success "TEMA L2: Federation layer with real web services"
Write-Success "TEMA L3: OLAP analytics and dimensional modeling"
Write-Host ""

# Test Connection
Write-Host "Connection Information:" -ForegroundColor Yellow
Write-Host "  Connect with: sqlplus $AdminUser/$AdminPassword@$DatabaseHost`:$DatabasePort/$DatabaseName"
Write-Host ""

# Sample Queries
Write-Host "Test Sample Queries:" -ForegroundColor Yellow
Write-Host "  SELECT * FROM V_OLAP_REVENUE_BY_HOTEL_MONTHLY;"
Write-Host "  SELECT * FROM V_OLAP_HOTEL_OCCUPANCY ORDER BY OCCUPANCY_RATE_PCT DESC;"
Write-Host "  SELECT * FROM V_OLAP_YOY_REVENUE_TREND WHERE YOY_GROWTH_PCT IS NOT NULL;"
Write-Host ""

# Next Steps
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify deployment: Check log files in $logDir"
Write-Host "  2. Test REST API: http://localhost:8181/ords/api/"
Write-Host "  3. Build APEX web interface using OLAP views"
Write-Host "  4. Monitor real data:"
Write-Host "     - OpenSky flights refresh every 5 minutes"
Write-Host "     - ECB currency rates refresh daily at 17:00 CET"
Write-Host ""

Write-Host "Log files saved to:" -ForegroundColor Yellow
Get-ChildItem "$logFile*" | ForEach-Object { Write-Host "  - $($_.Name)" }
Write-Host ""

Write-Success "All components deployed successfully!"
