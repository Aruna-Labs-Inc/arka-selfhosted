#!/bin/bash

set -e

# Colors
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SERVICE=${1:-}

if [ -z "$SERVICE" ]; then
    echo ""
    echo -e "  ${BOLD}📋 Viewing all logs${NC}"
    echo -e "  ${DIM}Press Ctrl+C to stop${NC}"
    echo ""
    docker-compose logs -f
else
    echo ""
    echo -e "  ${BOLD}📋 Viewing logs for: ${CYAN}${SERVICE}${NC}"
    echo -e "  ${DIM}Press Ctrl+C to stop${NC}"
    echo ""
    docker-compose logs -f "$SERVICE"
fi
