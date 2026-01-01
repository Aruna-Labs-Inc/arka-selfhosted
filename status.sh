#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "  ${BOLD}📊 Arka Status${NC}"
echo ""

echo -e "  ${BOLD}Services:${NC}"
docker-compose ps

echo ""
echo -e "  ${BOLD}Resource Usage:${NC}"
echo ""

# Get container stats (non-streaming, one-time)
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose ps -q 2>/dev/null) 2>/dev/null || echo "  No containers running"

echo ""
