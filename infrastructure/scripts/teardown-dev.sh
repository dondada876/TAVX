#!/bin/bash

# TAV-X Development Environment Teardown Script
# This script safely tears down the local development environment

set -e

echo "🛑 TAV-X Development Environment Teardown"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Confirm teardown
read -p "⚠️  This will stop and remove all Docker containers. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "🛑 Stopping Docker containers..."
docker-compose down

echo ""
read -p "❓ Do you want to remove volumes (deletes all data)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing volumes..."
    docker-compose down -v
    echo -e "${YELLOW}⚠️  All data has been deleted.${NC}"
else
    echo "Volumes preserved."
fi

echo ""
echo -e "${GREEN}✅ Teardown complete${NC}"
echo ""
echo "To start again: ./infrastructure/scripts/setup-dev.sh"
echo ""
