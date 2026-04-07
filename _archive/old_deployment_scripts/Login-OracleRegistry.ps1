# Login to Oracle Container Registry for Docker
# 
# Usage: .\Login-OracleRegistry.ps1
# 
# This script will prompt for your Oracle SSO credentials and Auth Token
# and log into the Oracle Container Registry.
#
# IMPORTANT: You need an Auth Token, NOT your account password!
# Get one from: https://container-registry.oracle.com
# - Click your profile → Auth Tokens → Generate Secret Key

param(
    [switch]$Logout
)

$registry = "container-registry.oracle.com"
$errorCount = 0

# Colors for output
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

Write-Host "`n" -ForegroundColor $infoColor
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $infoColor
Write-Host "║         Oracle Container Registry - Docker Authentication         ║" -ForegroundColor $infoColor
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $infoColor

if ($Logout) {
    Write-Host "`n[INFO] Logging out from $registry..." -ForegroundColor $infoColor
    docker logout $registry 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✓] Successfully logged out from Oracle Container Registry" -ForegroundColor $successColor
    } else {
        Write-Host "[✗] Failed to logout" -ForegroundColor $errorColor
    }
    exit
}

# Check if Docker is running
Write-Host "`n[CHECK] Verifying Docker is running..." -ForegroundColor $infoColor
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not responding"
    }
    Write-Host "[✓] Docker is running: $dockerVersion" -ForegroundColor $successColor
} catch {
    Write-Host "[✗] Docker is not running or not installed" -ForegroundColor $errorColor
    Write-Host "`nStart Docker Desktop and try again." -ForegroundColor $warningColor
    exit 1
}

# Prompt for credentials
Write-Host "`n[INPUT] Oracle Container Registry Credentials" -ForegroundColor $infoColor
Write-Host "`n   Registry: $registry" -ForegroundColor $infoColor
Write-Host "   Get your Auth Token from: https://container-registry.oracle.com" -ForegroundColor $warningColor
Write-Host "   - Sign in → Profile (top right) → Auth Tokens → Generate Secret Key" -ForegroundColor $warningColor

Write-Host "`n" 
$username = Read-Host "Enter your Oracle SSO username/email"

if ([string]::IsNullOrWhiteSpace($username)) {
    Write-Host "[✗] Username cannot be empty" -ForegroundColor $errorColor
    exit 1
}

$password = Read-Host "Enter your Auth Token (will be hidden)" -AsSecureString

if ($password.Length -eq 0) {
    Write-Host "[✗] Auth Token cannot be empty" -ForegroundColor $errorColor
    exit 1
}

# Convert SecureString to plain text for docker login
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemAlloc($password)
)

# Attempt Docker login
Write-Host "`n[ACTION] Authenticating with $registry..." -ForegroundColor $infoColor
Write-Host "         (This may take a few seconds...)" -ForegroundColor $infoColor

$loginOutput = docker login -u $username -p $plainPassword $registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[✓] Authentication successful!" -ForegroundColor $successColor
    Write-Host "    You are now logged in to: $registry" -ForegroundColor $successColor
    
    Write-Host "`n[NEXT] You can now pull Oracle images:" -ForegroundColor $infoColor
    Write-Host "       docker pull container-registry.oracle.com/database/free:latest" -ForegroundColor $infoColor
    
    Write-Host "`n[NEXT] Or start Docker Compose:" -ForegroundColor $infoColor
    Write-Host "       docker-compose -f docker-compose-db-only.yml -p tourism-platform up -d" -ForegroundColor $infoColor
} else {
    Write-Host "`n[✗] Authentication failed!" -ForegroundColor $errorColor
    Write-Host "`nCommon issues:" -ForegroundColor $warningColor
    Write-Host "  1. Using account password instead of Auth Token" -ForegroundColor $warningColor
    Write-Host "     → Generate Auth Token at: https://container-registry.oracle.com" -ForegroundColor $warningColor
    Write-Host "  2. Invalid username or token" -ForegroundColor $warningColor
    Write-Host "     → Check Oracle account and generate new token if needed" -ForegroundColor $warningColor
    Write-Host "  3. Network connectivity issue" -ForegroundColor $warningColor
    Write-Host "     → Check internet connection" -ForegroundColor $warningColor
    
    if ($loginOutput) {
        Write-Host "`nServer response:" -ForegroundColor $infoColor
        Write-Host $loginOutput -ForegroundColor $warningColor
    }
    exit 1
}

Write-Host "`n" -ForegroundColor $infoColor
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $infoColor
Write-Host "║         Setup complete! Ready to pull Oracle images               ║" -ForegroundColor $infoColor
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $infoColor
Write-Host "`n"

# Clean up SecureString
$plainPassword = $null
