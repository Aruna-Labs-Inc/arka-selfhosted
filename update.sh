#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

clear
echo ""
echo -e "  📦  ${BOLD}${CYAN}Updating Arka${NC}"
echo ""
echo -e "  ${DIM}Pulling latest image and restarting services${NC}"
echo ""

echo -e "  → Pulling latest Arka image..."
docker-compose pull arka

echo -e "  → Restarting services..."
docker-compose up -d

echo -e "  → Waiting for services to restart..."
sleep 5

echo ""
echo -e "  ${GREEN}✓${NC} ${BOLD}Update complete!${NC}"
echo ""
echo -e "  Service status:"
docker-compose ps
echo ""
