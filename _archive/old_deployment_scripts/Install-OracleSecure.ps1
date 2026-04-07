###############################################################################
# Oracle Database 21c Express Edition - Secure Installation Automation
# 
# This script automates the entire installation with security hardening
# Run as Administrator
#
###############################################################################

param(
    [string]$OracleZipPath = "C:\OracleXE213_Win64.zip",
    [string]$OracleHome = "C:\Oracle\product\21c",
    [string]$OracleBase = "C:\Oracle",
    [string]$DataPath = "D:\OracleData"
)

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "  Oracle Database 21c Express - SECURE Local Installation" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

###############################################################################
# Function: Check Prerequisites
###############################################################################
function Test-Prerequisites {
    Write-Host "[STEP 1/8] Checking Prerequisites..." -ForegroundColor Yellow
    
    # Check if running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        throw "ERROR: This script must be run as Administrator"
    }
    Write-Host "✓ Running as Administrator" -ForegroundColor Green
    
    # Check Windows version
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        throw "ERROR: Windows 10 or newer required"
    }
    Write-Host "✓ Windows version: $osVersion" -ForegroundColor Green
    
    # Check available disk space
    $diskSpace = Get-Volume -DriveLetter C | Select-Object -ExpandProperty SizeRemaining
    $diskSpaceGB = $diskSpace / 1GB
    if ($diskSpaceGB -lt 25) {
        throw "ERROR: Need at least 25GB free on C: drive (available: $diskSpaceGB GB)"
    }
    Write-Host "✓ Disk space: $diskSpaceGB GB available" -ForegroundColor Green
    
    # Check available RAM
    $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object -ExpandProperty Sum
    $ramGB = $ram / 1GB
    if ($ramGB -lt 8) {
        throw "ERROR: Need at least 8GB RAM (available: $ramGB GB)"
    }
    Write-Host "✓ System RAM: $ramGB GB" -ForegroundColor Green
    
    # Check if ZIP file exists
    if (-not (Test-Path $OracleZipPath)) {
        throw "ERROR: Oracle ZIP file not found at: $OracleZipPath"
    }
    Write-Host "✓ Oracle ZIP file found: $OracleZipPath" -ForegroundColor Green
    Write-Host ""
}

###############################################################################
# Function: Create Secure Service Account
###############################################################################
function New-SecureServiceAccount {
    Write-Host "[STEP 2/8] Creating Secure Service Account..." -ForegroundColor Yellow
    
    $username = "OracleService"
    $password = ConvertTo-SecureString "OracleP@ss2025!" -AsPlainText -Force
    
    # Check if user already exists
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "⚠ User '$username' already exists, skipping creation" -ForegroundColor Yellow
        return
    }
    
    try {
        # Create local user
        New-LocalUser -Name $username -Password $password `
            -FullName "Oracle Database Service" `
            -Description "Non-privileged service account for Oracle Database" `
            -PasswordNeverExpires $false -UserMayChangePassword $true | Out-Null
        
        # Add to Users group (not Administrators)
        Add-LocalGroupMember -Group "Users" -Member $username -ErrorAction SilentlyContinue
        
        Write-Host "✓ Service account created: $username" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Could not create service account (may already exist): $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

###############################################################################
# Function: Create Installation Directories with Secure ACLs
###############################################################################
function New-SecureDirectories {
    Write-Host "[STEP 3/8] Creating Installation Directories..." -ForegroundColor Yellow
    
    $directories = @($OracleBase, $OracleHome, $DataPath)
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "✓ Created: $dir" -ForegroundColor Green
        }
        else {
            Write-Host "✓ Already exists: $dir" -ForegroundColor Green
        }
        
        # Set ACLs - disable inheritance for security
        try {
            $acl = Get-Acl $dir
            # Remove inherited permissions
            $acl.SetAccessRuleProtection($true, $false)
            
            # Grant Administrators full control
            $adminAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($adminAce)
            
            # Grant OracleService account access
            $serviceAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
                ".\OracleService", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($serviceAce)
            
            Set-Acl -Path $dir -AclObject $acl
            Write-Host "  ✓ Security ACLs applied to: $dir" -ForegroundColor Green
        }
        catch {
            Write-Host "  ⚠ Could not set ACLs (may require admin privileges): $_" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

###############################################################################
# Function: Extract Oracle Installation Files
###############################################################################
function Expand-OracleFiles {
    Write-Host "[STEP 4/8] Extracting Oracle Installation Files..." -ForegroundColor Yellow
    
    $extractPath = "C:\OracleTemp"
    
    if (Test-Path $extractPath) {
        Write-Host "⚠ Extraction directory already exists, cleaning..." -ForegroundColor Yellow
        Remove-Item -Path $extractPath -Recurse -Force
    }
    
    Write-Host "Extracting $OracleZipPath to $extractPath (this may take 2-3 minutes)..."
    Expand-Archive -Path $OracleZipPath -DestinationPath $extractPath -Force
    
    Write-Host "✓ Installation files extracted" -ForegroundColor Green
    Write-Host ""
    
    return $extractPath
}

###############################################################################
# Function: Run Silent Installation
###############################################################################
function Install-OracleDatabase {
    param([string]$ExtractPath, [string]$ResponseFile)
    
    Write-Host "[STEP 5/8] Running Oracle Silent Installation..." -ForegroundColor Yellow
    Write-Host "This will take 15-30 minutes. Please wait..." -ForegroundColor Yellow
    
    $setupExe = Join-Path $ExtractPath "WINDOWS.X64_213000_db_home\setup.exe"
    
    if (-not (Test-Path $setupExe)) {
        throw "ERROR: Setup.exe not found at: $setupExe"
    }
    
    try {
        $process = Start-Process -FilePath $setupExe `
            -ArgumentList "-silent -responseFile `"$ResponseFile`"" `
            -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✓ Installation completed successfully" -ForegroundColor Green
        }
        else {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        throw "ERROR during installation: $_"
    }
    
    Write-Host ""
}

###############################################################################
# Function: Post-Installation Security Configuration
###############################################################################
function Set-SecurityConfiguration {
    Write-Host "[STEP 6/8] Applying Security Configuration..." -ForegroundColor Yellow
    
    # Set environment variables
    [Environment]::SetEnvironmentVariable("ORACLE_HOME", $OracleHome, "Machine")
    [Environment]::SetEnvironmentVariable("ORACLE_BASE", $OracleBase, "Machine")
    [Environment]::SetEnvironmentVariable("ORACLE_SID", "XEPDB1", "Machine")
    
    Write-Host "✓ Environment variables set" -ForegroundColor Green
    
    # Create security hardening SQL script
    $securitySql = @"
-- Oracle Post-Installation Security Hardening
-- Run this as SYSTEM user

-- 1. Enable Password Policy
ALTER PROFILE DEFAULT LIMIT
  PASSWORD_LIFE_TIME 90
  PASSWORD_GRACE_TIME 7
  PASSWORD_REUSE_TIME UNLIMITED
  PASSWORD_REUSE_MAX 3
  FAILED_LOGIN_ATTEMPTS 3
  PASSWORD_LOCK_TIME 1;

-- 2. Lock unused default accounts
ALTER USER SCOTT ACCOUNT LOCK;
ALTER USER SH ACCOUNT LOCK;
ALTER USER HR ACCOUNT LOCK;
ALTER USER OE ACCOUNT LOCK;
ALTER USER PM ACCOUNT LOCK;

-- 3. Enable basic auditing
AUDIT CONNECT BY SYSTEM BY ACCESS;
AUDIT CREATE TABLE BY SYSTEM BY ACCESS;
AUDIT DROP TABLE BY SYSTEM BY ACCESS;

COMMIT;

-- 4. Create application user with minimal privileges
CREATE USER TOURISM_ADMIN IDENTIFIED BY "Tourism2025!@Secure"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;

GRANT CREATE SESSION TO TOURISM_ADMIN;
GRANT CREATE TABLE TO TOURISM_ADMIN;
GRANT CREATE VIEW TO TOURISM_ADMIN;
GRANT CREATE PROCEDURE TO TOURISM_ADMIN;
GRANT CREATE SEQUENCE TO TOURISM_ADMIN;
GRANT UNLIMITED TABLESPACE TO TOURISM_ADMIN;

COMMIT;

-- Security verification:
SELECT USERNAME, ACCOUNT_STATUS FROM dba_users WHERE USERNAME IN ('SCOTT','SH','HR','OE','PM');
SHOW PARAMETER password;
"@
    
    $scriptPath = Join-Path $OracleBase "security_hardening.sql"
    Set-Content -Path $scriptPath -Value $securitySql
    
    Write-Host "✓ Security hardening script created at: $scriptPath" -ForegroundColor Green
    Write-Host ""
}

###############################################################################
# Function: Configure Windows Firewall
###############################################################################
function Set-FirewallRules {
    Write-Host "[STEP 7/8] Configuring Windows Firewall..." -ForegroundColor Yellow
    
    try {
        # SQL*Net listener - localhost only
        New-NetFirewallRule -DisplayName "Oracle SQL*Net - Local Only" `
            -Direction Inbound -LocalPort 1521 -Protocol TCP `
            -RemoteAddress 127.0.0.1 -Action Allow `
            -ErrorAction SilentlyContinue | Out-Null
        
        Write-Host "✓ Firewall rule created: Oracle SQL*Net (Localhost only)" -ForegroundColor Green
        
        # EM Express (port 5500) - localhost only
        New-NetFirewallRule -DisplayName "Oracle EM Express - Local Only" `
            -Direction Inbound -LocalPort 5500 -Protocol TCP `
            -RemoteAddress 127.0.0.1 -Action Allow `
            -ErrorAction SilentlyContinue | Out-Null
        
        Write-Host "✓ Firewall rule created: Oracle EM Express (Localhost only)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Could not set firewall rules: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

###############################################################################
# Function: Create Connection Test Script
###############################################################################
function New-ConnectionTestScript {
    Write-Host "[STEP 8/8] Creating Connection Test Script..." -ForegroundColor Yellow
    
    $testScript = @"
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Oracle Database Connection Test
@ 
@ Usage: sqlplus TOURISM_ADMIN/Tourism2025!@Secure@localhost:1521/XEPDB1
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- Test 1: Verify connection
SELECT 'Oracle Database is running!' AS status FROM dual;

-- Test 2: Check database version
SELECT * FROM v\$version WHERE ROWNUM = 1;

-- Test 3: Verify user privileges
SELECT USERNAME, ACCOUNT_STATUS FROM dba_users WHERE USERNAME = 'TOURISM_ADMIN';

-- Test 4: Check security settings
SELECT NAME, VALUE FROM v\$parameter WHERE NAME LIKE 'password%' OR NAME LIKE 'audit%';

-- Commit and exit
COMMIT;
EXIT;
"@
    
    $scriptPath = Join-Path $OracleBase "test_connection.sql"
    Set-Content -Path $scriptPath -Value $testScript
    
    Write-Host "✓ Connection test script created at: $scriptPath" -ForegroundColor Green
    Write-Host ""
}

###############################################################################
# Function: Display Summary
###############################################################################
function Show-InstallationSummary {
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Installation Details:" -ForegroundColor Cyan
    Write-Host "  Oracle Home: $OracleHome" -ForegroundColor White
    Write-Host "  Oracle Base: $OracleBase" -ForegroundColor White
    Write-Host "  Data Path:   $DataPath" -ForegroundColor White
    Write-Host "  SID:         XEPDB1" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Connection String:" -ForegroundColor Cyan
    Write-Host "  sqlplus TOURISM_ADMIN/Tourism2025!@Secure@localhost:1521/XEPDB1" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Apply security hardening:" -ForegroundColor White
    Write-Host "     sqlplus system/Tourism2025!@Secure@localhost:1521/XEPDB1 @$(Join-Path $OracleBase 'security_hardening.sql')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Test connection:" -ForegroundColor White
    Write-Host "     sqlplus TOURISM_ADMIN/Tourism2025!@Secure@localhost:1521/XEPDB1 @$(Join-Path $OracleBase 'test_connection.sql')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Deploy TEMA scripts:" -ForegroundColor White
    Write-Host "     sqlplus TOURISM_ADMIN/Tourism2025!@Secure@localhost:1521/XEPDB1 @database\TEMA_L2_FEDERATED_ACCESS.sql" -ForegroundColor Gray
    Write-Host "     sqlplus TOURISM_ADMIN/Tourism2025!@Secure@localhost:1521/XEPDB1 @database\TEMA_L3_OLAP_VIEWS.sql" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Security Reminders:" -ForegroundColor Cyan
    Write-Host "  ⚠ Change the SYS and SYSTEM passwords immediately!" -ForegroundColor Yellow
    Write-Host "  ⚠ Never share oracle_install.rsp (contains passwords)" -ForegroundColor Yellow
    Write-Host "  ⚠ Enable backups and disaster recovery" -ForegroundColor Yellow
    Write-Host "  ⚠ Review security_hardening.sql before running" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "===============================================================================" -ForegroundColor Green
}

###############################################################################
# MAIN EXECUTION
###############################################################################

try {
    Test-Prerequisites
    
    # Check if response file exists
    $responseFile = "C:\oracle_install.rsp"
    if (-not (Test-Path $responseFile)) {
        throw "ERROR: Response file not found at: $responseFile`nPlease copy oracle_install.rsp from the repository to C:\oracle_install.rsp"
    }
    
    New-SecureServiceAccount
    New-SecureDirectories
    $extractPath = Expand-OracleFiles
    Install-OracleDatabase -ExtractPath $extractPath -ResponseFile $responseFile
    Set-SecurityConfiguration
    Set-FirewallRules
    New-ConnectionTestScript
    Show-InstallationSummary
    
    Write-Host "Installation SUCCESS!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host "  INSTALLATION FAILED" -ForegroundColor Red
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check installation logs at: C:\Oracle\product\21c\install\logs\" -ForegroundColor White
    Write-Host "  2. Ensure prerequisites are met (8GB RAM, 25GB disk)" -ForegroundColor White
    Write-Host "  3. Run as Administrator" -ForegroundColor White
    Write-Host "  4. Review response file: C:\oracle_install.rsp" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
