#!/bin/bash

set -e

# Colors
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "  ⏸️   ${BOLD}Stopping Arka${NC}"
echo ""
echo -e "  ${DIM}Services will be stopped but data will be preserved${NC}"
echo ""

docker-compose stop

echo ""
echo -e "  ${BOLD}✓ Arka stopped${NC}"
echo -e "  ${DIM}Data is preserved in Docker volumes${NC}"
echo ""
echo -e "  To start again: ${CYAN}./start.sh${NC}"
echo ""
