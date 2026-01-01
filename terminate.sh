#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

clear
echo ""
echo -e "  🗑️   ${BOLD}${RED}Terminate Arka${NC}"
echo ""
echo -e "  ${YELLOW}⚠  WARNING: This will:${NC}"
echo -e "     ${DIM}• Stop all Arka services${NC}"
echo -e "     ${DIM}• Delete all data (database, files)${NC}"
echo -e "     ${DIM}• Remove Docker containers and volumes${NC}"
echo ""
read -p "  Are you sure? [y/N]: " confirm
echo ""

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "  ${CYAN}→${NC} Cancelled"
    echo ""
    exit 0
fi

echo -e "  → Stopping services..."
docker-compose down

echo -e "  → Removing volumes..."
docker-compose down -v

echo -e "  → Cleaning up..."
rm -f .env docker-compose.yml.bak

echo ""
echo -e "  ${BOLD}✓ Arka has been terminated${NC}"
echo -e "  ${DIM}All data has been removed${NC}"
echo ""
