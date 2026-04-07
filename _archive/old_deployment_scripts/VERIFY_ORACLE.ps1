#!/usr/bin/env powershell
#============================================================================
# Tourism Analysis Platform - Quick Verification
#============================================================================
# Check if Oracle is accessible before running deployment
# Usage: powershell -ExecutionPolicy Bypass -File VERIFY_ORACLE.ps1
#============================================================================

param(
    [string]$DatabaseHost = "localhost",
    [int]$DatabasePort = 1521,
    [string]$DatabaseName = "FREEPDB1",
    [string]$AdminUser = "TOURISM_ADMIN",
    [string]$AdminPassword = "Tourism2025!"
)

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Tourism Analysis Platform - Oracle Database Verification" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: SQL*Plus availability
Write-Host "[1/5] Checking SQL*Plus availability..." -ForegroundColor Yellow
try {
    $output = sqlplus -v 2>&1 | Select-Object -First 1
    if ($output -match "SQL\*Plus") {
        Write-Host "✓ SQL*Plus found: $output" -ForegroundColor Green
    }
    else {
        Write-Host "✗ SQL*Plus not found or not in PATH" -ForegroundColor Red
        Write-Host "  Install Oracle Client or Database from:" -ForegroundColor Yellow
        Write-Host "  https://www.oracle.com/database/technologies/instant-client/downloads.html"
        exit 1
    }
}
catch {
    Write-Host "✗ SQL*Plus command failed: $_" -ForegroundColor Red
    exit 1
}

# Check 2: Port Accessibility
Write-Host ""
Write-Host "[2/5] Checking database port ($DatabasePort)..." -ForegroundColor Yellow
$portTest = Test-NetConnection -ComputerName $DatabaseHost -Port $DatabasePort -WarningAction SilentlyContinue
if ($portTest.TcpTestSucceeded) {
    Write-Host "✓ Port $DatabasePort is accessible on $DatabaseHost" -ForegroundColor Green
}
else {
    Write-Host "⚠ Port $DatabasePort is NOT accessible on $DatabaseHost" -ForegroundColor Yellow
    Write-Host "  This usually means:"
    Write-Host "  - Oracle database is not running"
    Write-Host "  - Firewall is blocking the connection"
    Write-Host "  - Database is on a different host/port"
}

# Check 3: Connection String
Write-Host ""
Write-Host "[3/5] Testing database connection..." -ForegroundColor Yellow
$connString = "$AdminUser/$AdminPassword@$DatabaseHost`:$DatabasePort/$DatabaseName"
Write-Host "  Connection: $connString" -ForegroundColor Cyan

# Create temporary SQL script to test
$testScript = @"
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 1000
SELECT 'CONNECTION_SUCCESS' FROM DUAL;
EXIT;
"@

$tempScript = "$env:TEMP\test_connection.sql"
$testScript | Out-File -FilePath $tempScript -Encoding ASCII
$tempOutput = "$env:TEMP\test_connection.out"

try {
    # Try to connect
    $process = Start-Process -FilePath "sqlplus" `
        -ArgumentList "-S $connString `"@$tempScript`"" `
        -RedirectStandardOutput $tempOutput `
        -RedirectStandardError "$tempOutput.err" `
        -NoNewWindow `
        -Wait `
        -PassThru
    
    $result = Get-Content $tempOutput | Select-String "CONNECTION_SUCCESS"
    
    if ($result) {
        Write-Host "✓ Database connection successful!" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Database connection failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error output:" -ForegroundColor Yellow
        Get-Content "$tempOutput.err" | Select-Object -First 5 | Write-Host
        exit 1
    }
}
catch {
    Write-Host "✗ Connection test error: $_" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path $tempScript) { Remove-Item $tempScript }
    if (Test-Path $tempOutput) { Remove-Item $tempOutput }
    if (Test-Path "$tempOutput.err") { Remove-Item "$tempOutput.err" }
}

# Check 4: SQL Scripts Exist
Write-Host ""
Write-Host "[4/5] Checking SQL scripts..." -ForegroundColor Yellow
$scriptDir = Join-Path (Split-Path $PSScriptRoot) "database"
$requiredScripts = @(
    "init_db.sql",
    "TEMA_L2_FEDERATED_ACCESS.sql",
    "TEMA_L2_ORDS_REST_SERVICES.sql",
    "TEMA_L3_OLAP_VIEWS.sql",
    "TEMA_L3_VERIFY.sql"
)

$allFound = $true
foreach ($script in $requiredScripts) {
    $path = Join-Path $scriptDir $script
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        Write-Host "✓ $script ($('{0:N0}' -f $size) bytes)" -ForegroundColor Green
    }
    else {
        Write-Host "✗ $script NOT FOUND" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    Write-Host "  Expected location: $scriptDir" -ForegroundColor Yellow
    exit 1
}

# Check 5: Required Tables/Views
Write-Host ""
Write-Host "[5/5] Checking if deployment needed..." -ForegroundColor Yellow

$checkScript = @"
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 1000
SELECT COUNT(*) FROM user_tables WHERE table_name LIKE 'DIM_%' OR table_name LIKE 'FACT_%';
EXIT;
"@

$tempScript = "$env:TEMP\check_objects.sql"
$checkScript | Out-File -FilePath $tempScript -Encoding ASCII
$tempOutput = "$env:TEMP\check_objects.out"

try {
    Start-Process -FilePath "sqlplus" `
        -ArgumentList "-S $connString `"@$tempScript`"" `
        -RedirectStandardOutput $tempOutput `
        -NoNewWindow `
        -Wait | Out-Null
    
    $count = [int](Get-Content $tempOutput | Select-String -Pattern "\d+" -AllMatches | ForEach-Object { $_.Matches.Value } | Select-Object -First 1)
    
    if ($count -gt 0) {
        Write-Host "✓ TEMA L3 objects already deployed ($count tables/views found)" -ForegroundColor Green
        Write-Host "  To redeploy, run: DEPLOY.ps1"
    }
    else {
        Write-Host "ℹ TEMA L3 objects not found - deployment needed" -ForegroundColor Cyan
        Write-Host "  Run: .\DEPLOY.ps1 -DatabaseHost $DatabaseHost -DatabasePort $DatabasePort -DatabaseName $DatabaseName"
    }
}
catch {
    Write-Host "⚠ Could not check for existing objects: $_" -ForegroundColor Yellow
}
finally {
    if (Test-Path $tempScript) { Remove-Item $tempScript }
    if (Test-Path $tempOutput) { Remove-Item $tempOutput }
}

# Summary
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "Verification Complete" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "System Status:" -ForegroundColor Yellow
Write-Host "  ✓ SQL*Plus: Ready"
Write-Host "  $(if($portTest.TcpTestSucceeded) {'✓'} else {'⚠'}) Port $DatabasePort : $(if($portTest.TcpTestSucceeded) {'Accessible'} else {'Not accessible'})"
Write-Host "  ✓ Connection: Working"
Write-Host "  ✓ SQL Scripts: Found"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run deployment: .\DEPLOY.ps1"
Write-Host "  2. Or use batch: DEPLOY.bat"
Write-Host ""
