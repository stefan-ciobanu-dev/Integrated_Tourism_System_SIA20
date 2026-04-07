#!/bin/bash

# ============================================================================
# Tourism Analysis Platform - Start Stack Script
# Platforma de analiza a turismului - Script de pornire
# 
# Purpose: Starts the entire Docker Compose stack (Oracle DB + ORDS)
# Usage: ./start.sh
#
# Error Handling:
#   - Checks if Docker is installed and running
#   - Validates docker-compose.yml exists
#   - Provides clear error messages on failure
#   - Displays startup progress and connection information
# ============================================================================

set -euo pipefail  # Exit on error, undefined variables, or pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ============================================================================
# Configuration
# ============================================================================

COMPOSE_FILE="docker-compose.yml"
STACK_NAME="tourism-platform"
STARTUP_WAIT_TIME=120  # seconds to wait for services to be healthy

# ============================================================================
# Helper Functions
# ============================================================================

# Print colored output with level prefix
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Script encountered an error (Exit code: $exit_code)"
        print_info "Attempting to stop containers..."
        docker-compose down 2>/dev/null || true
    fi
    exit $exit_code
}

trap cleanup EXIT

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_info "Starting Tourism Analysis Platform..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker daemon is not running"
    exit 1
fi

print_success "Docker is available and running"

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose not found, trying 'docker compose'..."
    if ! docker compose version > /dev/null 2>&1; then
        print_error "Neither docker-compose nor 'docker compose' is available"
        exit 1
    fi
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

print_success "Docker Compose is available"

# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "docker-compose.yml not found in current directory"
    print_info "Current directory: $(pwd)"
    exit 1
fi

print_success "docker-compose.yml found"

# ============================================================================
# Create Required Directories
# ============================================================================

print_info "Creating required directories for volumes..."

mkdir -p database/data
mkdir -p database/logs
mkdir -p database/exports
mkdir -p ords/config
mkdir -p ords/logs

print_success "Directories created successfully"

# ============================================================================
# Start Services
# ============================================================================

print_info ""
print_info "Starting Docker Compose stack..."
print_info "This may take 2-3 minutes on first run..."
echo ""

# Start services in detached mode
$COMPOSE_CMD -p "$STACK_NAME" up -d

if [ $? -ne 0 ]; then
    print_error "Failed to start Docker Compose stack"
    exit 1
fi

print_success "Docker Compose stack started"

# ============================================================================
# Wait for Services to Be Healthy
# ============================================================================

print_info ""
print_info "Waiting for services to become healthy (max ${STARTUP_WAIT_TIME}s)..."
echo ""

elapsed=0
interval=5
oracle_healthy=false
ords_healthy=false

while [ $elapsed -lt $STARTUP_WAIT_TIME ]; do
    # Check Oracle DB health
    if ! $oracle_healthy; then
        if $COMPOSE_CMD -p "$STACK_NAME" ps oracle-db | grep -q "healthy"; then
            print_success "Oracle Database is healthy"
            oracle_healthy=true
        fi
    fi
    
    # Check ORDS health
    if ! $ords_healthy; then
        if $COMPOSE_CMD -p "$STACK_NAME" ps ords | grep -q "healthy"; then
            print_success "ORDS is healthy"
            ords_healthy=true
        fi
    fi
    
    # Both services healthy - we're done waiting
    if $oracle_healthy && $ords_healthy; then
        print_success "All services are healthy!"
        break
    fi
    
    # Print progress indicator
    if [ $((elapsed % 15)) -eq 0 ] && [ $elapsed -gt 0 ]; then
        print_info "Waiting... (${elapsed}s elapsed)"
    fi
    
    sleep $interval
    elapsed=$((elapsed + interval))
done

# Timeout warning
if ! $oracle_healthy || ! $ords_healthy; then
    print_warning "Timeout waiting for all services to be healthy"
    print_info "This is normal on first startup - initialization continues in background"
    print_info "Check service logs with: $COMPOSE_CMD logs -f"
fi

# ============================================================================
# Display Connection Information
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║          Tourism Analysis Platform - Startup Complete!            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

print_success "Docker Stack: $STACK_NAME"
echo ""

echo "📊 Oracle Database (FREEPDB1)"
echo "  Host:        localhost"
echo "  Port:        1521"
echo "  SID:         FREEPDB1"
echo "  System User: system"
echo "  Sys User:    sys"
echo "  Password:    TourismDB2025!"
echo ""

echo "🔑 Application User (TOURISM_ADMIN)"
echo "  Username:    TOURISM_ADMIN"
echo "  Password:    Tourism2025"
echo ""

echo "🌐 ORDS (Oracle REST Data Services)"
echo "  URL:         http://localhost:8181/ords/"
echo "  Port:        8181"
echo ""

echo "💾 Enterprise Manager Express"
echo "  URL:         https://localhost:5500/em/"
echo "  Username:    sys"
echo "  Password:    TourismDB2025!"
echo ""

# ============================================================================
# Useful Commands
# ============================================================================

echo "📝 Useful Commands:"
echo "  View logs:        $COMPOSE_CMD -p $STACK_NAME logs -f"
echo "  View DB logs:     $COMPOSE_CMD -p $STACK_NAME logs -f oracle-db"
echo "  View ORDS logs:   $COMPOSE_CMD -p $STACK_NAME logs -f ords"
echo "  Stop stack:       $COMPOSE_CMD -p $STACK_NAME down"
echo "  Stop + cleanup:   $COMPOSE_CMD -p $STACK_NAME down -v"
echo "  Check status:     ./health-check.sh"
echo ""

print_success "Platform ready to use! 🚀"
