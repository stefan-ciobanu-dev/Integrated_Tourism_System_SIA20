#!/bin/bash

# ============================================================================
# Tourism Analysis Platform - Stop Stack Script
# Platforma de analiza a turismului - Script de oprire
# 
# Purpose: Gracefully stops the Docker Compose stack with data preservation
# Usage: ./stop.sh [--full]    (--full removes all volumes)
#
# Options:
#   --full    Remove all volumes and temporary data (use with caution!)
#   (default) Stop containers but preserve data
#
# Error Handling:
#   - Checks if Docker is available
#   - Provides graceful shutdown
#   - Clear status messages
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
FULL_CLEANUP=false

# ============================================================================
# Helper Functions
# ============================================================================

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

# ============================================================================
# Parse Command Line Arguments
# ============================================================================

while [ $# -gt 0 ]; do
    case $1 in
        --full)
            FULL_CLEANUP=true
            print_warning "Full cleanup mode enabled - volumes will be deleted!"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: $0 [--full]"
            exit 1
            ;;
    esac
done

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_info "Stopping Tourism Analysis Platform..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
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
# Check Current Stack Status
# ============================================================================

print_info ""
print_info "Checking current stack status..."

# Count running containers
running_count=$($COMPOSE_CMD -p "$STACK_NAME" ps -q 2>/dev/null | wc -l || echo "0")

if [ "$running_count" -eq 0 ]; then
    print_warning "No running containers found for this stack"
    echo "The stack may already be stopped."
    exit 0
fi

print_success "Found $running_count running container(s)"

# ============================================================================
# Stop Services
# ============================================================================

print_info ""
print_info "Stopping services... (this may take up to 30 seconds)"
echo ""

# Gracefully stop containers with a timeout of 30 seconds
if ! $COMPOSE_CMD -p "$STACK_NAME" stop -t 30; then
    print_warning "Graceful stop timeout - forcing container termination"
    $COMPOSE_CMD -p "$STACK_NAME" kill || true
fi

print_success "Services stopped"

# ============================================================================
# Down Stack (Remove Containers)
# ============================================================================

print_info ""
print_info "Removing containers and networks..."

if [ "$FULL_CLEANUP" = true ]; then
    # Full cleanup - remove volumes too
    print_warning "Removing all volumes (data will be deleted!)..."
    sleep 2  # Give user time to read warning
    
    if $COMPOSE_CMD -p "$STACK_NAME" down -v; then
        print_success "Stack completely removed with all volumes deleted"
    else
        print_error "Failed to remove stack with volumes"
        exit 1
    fi
else
    # Normal cleanup - preserve volumes
    if $COMPOSE_CMD -p "$STACK_NAME" down; then
        print_success "Stack removed (data volumes preserved)"
    else
        print_error "Failed to remove stack"
        exit 1
    fi
fi

# ============================================================================
# Display Summary
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║       Tourism Analysis Platform - Shutdown Complete!              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

if [ "$FULL_CLEANUP" = true ]; then
    print_warning "Full cleanup performed - all volumes have been deleted"
    print_info "To restore, you'll need to restart from scratch with: ./start.sh"
else
    print_success "All data has been preserved"
    print_info "To restart the stack: ./start.sh"
    print_info "To perform full cleanup (remove all data): ./stop.sh --full"
fi

echo ""
print_success "Platform safely shut down! 🛑"
