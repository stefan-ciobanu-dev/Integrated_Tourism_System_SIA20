#!/bin/bash

# ============================================================================
# Tourism Analysis Platform - Health Check Script
# Platforma de analiza a turismului - Script de verificare stare
# 
# Purpose: Checks the health status of all platform services
# Usage: ./health-check.sh [--verbose]
#
# Output:
#   - Service status (running, healthy, unhealthy)
#   - Port connectivity checks
#   - Database connectivity test
#   - ORDS connectivity test
#
# Options:
#   --verbose    Show detailed logs for each service
# ============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m'  # No Color

# ============================================================================
# Configuration
# ============================================================================

STACK_NAME="tourism-platform"
VERBOSE=false
DB_HOST="localhost"
DB_PORT="1521"
ORDS_HOST="localhost"
ORDS_PORT="8181"

# ============================================================================
# Helper Functions
# ============================================================================

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_status() {
    echo -e "${ORANGE}[●]${NC} $1"
}

# Parse arguments
while [ $# -gt 0 ]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_info "Checking Docker Compose availability..."

if ! command -v docker-compose &> /dev/null; then
    if ! docker compose version > /dev/null 2>&1; then
        print_error "Docker Compose not available"
        exit 1
    fi
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

print_success "Docker Compose available"

if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found"
    exit 1
fi

# ============================================================================
# Check Container Status
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║               Tourism Platform - Health Check                     ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

print_info "Checking container status..."
echo ""

# Get container information
oracle_info=$($COMPOSE_CMD -p "$STACK_NAME" ps oracle-db 2>/dev/null || echo "")
ords_info=$($COMPOSE_CMD -p "$STACK_NAME" ps ords 2>/dev/null || echo "")

# Check if any containers exist
if [ -z "$oracle_info" ] && [ -z "$ords_info" ]; then
    print_warning "No containers found for stack: $STACK_NAME"
    print_info "Stack may not be running. Start it with: ./start.sh"
    exit 1
fi

# Oracle Database status
echo "📊 Oracle Database (FREEPDB1)"
echo "─────────────────────────────────────────────────────────────────"
if echo "$oracle_info" | grep -q "CONTAINER ID"; then
    if echo "$oracle_info" | grep -q "healthy"; then
        print_success "Container is HEALTHY"
    elif echo "$oracle_info" | grep -q "starting"; then
        print_warning "Container is STARTING"
    elif echo "$oracle_info" | grep -q "Up"; then
        print_status "Container is RUNNING (checking health...)"
    else
        print_error "Container status: $(echo "$oracle_info" | grep -o 'Up.*' || echo 'Unknown')"
    fi
else
    print_error "Container not found"
fi

# Extract and display container details
if [ -n "$oracle_info" ]; then
    container_id=$(echo "$oracle_info" | tail -1 | awk '{print $1}')
    status=$(echo "$oracle_info" | tail -1 | awk '{print $NF}')
    
    print_status "Container ID: ${container_id:0:12}"
    print_status "Status: $status"
fi

echo ""

# ORDS status
echo "🌐 ORDS (Oracle REST Data Services)"
echo "─────────────────────────────────────────────────────────────────"
if echo "$ords_info" | grep -q "CONTAINER ID"; then
    if echo "$ords_info" | grep -q "healthy"; then
        print_success "Container is HEALTHY"
    elif echo "$ords_info" | grep -q "starting"; then
        print_warning "Container is STARTING"
    elif echo "$ords_info" | grep -q "Up"; then
        print_status "Container is RUNNING (checking health...)"
    else
        print_error "Container status: $(echo "$ords_info" | grep -o 'Up.*' || echo 'Unknown')"
    fi
else
    print_error "Container not found"
fi

# Extract and display container details
if [ -n "$ords_info" ]; then
    container_id=$(echo "$ords_info" | tail -1 | awk '{print $1}')
    status=$(echo "$ords_info" | tail -1 | awk '{print $NF}')
    
    print_status "Container ID: ${container_id:0:12}"
    print_status "Status: $status"
fi

# ============================================================================
# Port Connectivity Checks
# ============================================================================

echo ""
echo "🔌 Port Connectivity Checks"
echo "─────────────────────────────────────────────────────────────────"

# Check Oracle port
if timeout 2 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "Oracle Database port ($DB_HOST:$DB_PORT) is OPEN"
else
    print_warning "Oracle Database port ($DB_HOST:$DB_PORT) is not responding"
fi

# Check ORDS port
if timeout 2 bash -c "echo > /dev/tcp/$ORDS_HOST/$ORDS_PORT" 2>/dev/null; then
    print_success "ORDS port ($ORDS_HOST:$ORDS_PORT) is OPEN"
else
    print_warning "ORDS port ($ORDS_HOST:$ORDS_PORT) is not responding"
fi

# ============================================================================
# Database Connectivity Test
# ============================================================================

echo ""
echo "💾 Database Connectivity"
echo "─────────────────────────────────────────────────────────────────"

# Try to connect with sqlplus if available
if command -v sqlplus &> /dev/null; then
    if timeout 10 sqlplus -v &>/dev/null; then
        print_status "Attempting SQL*Plus connection..."
        if timeout 10 sqlplus -s /nolog << 'EOF' > /tmp/db_test.log 2>&1
SET HEADING OFF FEEDBACK OFF VERIFY OFF TRIMSPOOL ON PAGESIZE 0 LINESIZE 1000
CONNECT system/TourismDB2025!@localhost:1521/FREEPDB1
SELECT 'Connection successful' FROM dual;
EXIT;
EOF
        then
            if grep -q "Connection successful" /tmp/db_test.log; then
                print_success "Database connection successful"
                print_status "User: system"
            else
                print_warning "Database connection test inconclusive"
            fi
        else
            print_warning "Database connection timed out or failed"
        fi
        rm -f /tmp/db_test.log
    fi
else
    print_status "SQL*Plus not installed - skipping database connection test"
fi

# ============================================================================
# ORDS REST Endpoint Test
# ============================================================================

echo ""
echo "🌐 ORDS REST Service"
echo "─────────────────────────────────────────────────────────────────"

if command -v curl &> /dev/null; then
    if timeout 5 curl -s -f "http://$ORDS_HOST:$ORDS_PORT/ords/" > /dev/null 2>&1; then
        print_success "ORDS REST service is responding"
        print_status "Endpoint: http://$ORDS_HOST:$ORDS_PORT/ords/"
    else
        print_warning "ORDS REST service not responding or not ready"
        print_info "This is normal during initial startup"
    fi
else
    print_status "curl not installed - skipping REST endpoint test"
fi

# ============================================================================
# Verbose Output (Logs)
# ============================================================================

if [ "$VERBOSE" = true ]; then
    echo ""
    echo "📋 Service Logs (verbose mode)"
    echo "─────────────────────────────────────────────────────────────────"
    echo ""
    
    echo "Oracle Database recent logs:"
    $COMPOSE_CMD -p "$STACK_NAME" logs --tail=10 oracle-db 2>/dev/null || print_warning "Could not fetch Oracle logs"
    
    echo ""
    echo "ORDS recent logs:"
    $COMPOSE_CMD -p "$STACK_NAME" logs --tail=10 ords 2>/dev/null || print_warning "Could not fetch ORDS logs"
fi

# ============================================================================
# Summary and Recommendations
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                        Health Check Complete                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

print_info "Connection Details:"
echo "  Oracle:  system/TourismDB2025!@localhost:1521/FREEPDB1"
echo "  App User: TOURISM_ADMIN / Tourism2025"
echo "  ORDS:    http://localhost:8181/ords/"
echo ""

print_info "Useful Commands:"
echo "  Real-time logs:   docker-compose logs -f"
echo "  DB logs only:     docker-compose logs -f oracle-db"
echo "  ORDS logs only:   docker-compose logs -f ords"
echo "  Stop services:    ./stop.sh"
echo "  Full verbose:     ./health-check.sh --verbose"
echo ""
