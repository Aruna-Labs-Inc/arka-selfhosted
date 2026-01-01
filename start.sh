#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "  ▶️   ${BOLD}${CYAN}Starting Arka${NC}"
echo ""

docker-compose start

echo ""
echo -e "  → Waiting for services to start..."
sleep 5

echo ""
echo -e "  ${GREEN}✓${NC} ${BOLD}Arka is running!${NC}"
echo ""

# Get the port from docker-compose
PORT=$(docker-compose port arka 3000 2>/dev/null | cut -d: -f2 || echo "3000")

echo -e "  🌐 Open in your browser:"
echo -e "     ${BOLD}${CYAN}http://localhost:${PORT}${NC}"
echo ""
