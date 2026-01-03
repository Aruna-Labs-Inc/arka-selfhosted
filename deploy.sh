#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Emojis
ROCKET="🚀"
CHECK="✓"
WRENCH="🔧"
PACKAGE="📦"
SPARKLES="✨"

clear
echo ""
echo -e "  ${ROCKET}  ${BOLD}${CYAN}Arka Self-Hosted Demo Deployment${NC}"
echo ""
echo -e "  ${DIM}Running Arka locally with Docker${NC}"
echo ""

# Check prerequisites
echo -e "${BOLD}  ${WRENCH} Checking Prerequisites${NC}"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "  ${RED}✗${NC} Docker is not installed"
    echo -e "  ${DIM}Install: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi
echo -e "  ${GREEN}${CHECK}${NC} Docker"

if ! docker info &> /dev/null; then
    echo -e "  ${RED}✗${NC} Docker daemon is not running"
    echo -e "  ${DIM}Start Docker Desktop or run: sudo systemctl start docker${NC}"
    exit 1
fi
echo -e "  ${GREEN}${CHECK}${NC} Docker daemon running"

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "  ${RED}✗${NC} docker-compose is not installed"
    echo -e "  ${DIM}Install: https://docs.docker.com/compose/install/${NC}"
    exit 1
fi
echo -e "  ${GREEN}${CHECK}${NC} docker-compose"

echo ""

# Check if port 3000 is available
echo -e "${BOLD}  🔍 Checking Port Availability${NC}"
echo ""

if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "  ${RED}${BOLD}⚠️  WARNING: Port 3000 is already in use${NC}"
    echo -e "  ${DIM}Another service is using port 3000${NC}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}⚠️  IMPORTANT:${NC} ${BOLD}BigQuery OAuth requires localhost:3000${NC}"
    echo -e "  ${DIM}Using a different port will prevent BigQuery OAuth from working.${NC}"
    echo -e "  ${DIM}This is the fastest way to connect BigQuery on local machines.${NC}"
    echo ""
    echo -e "  ${BOLD}What would you like to do?${NC}"
    echo ""
    echo -e "    ${BOLD}1)${NC} Use a different port (${YELLOW}BigQuery OAuth will NOT work${NC})"
    echo -e "    ${BOLD}2)${NC} Exit - I'll stop the other service (${GREEN}Recommended${NC})"
    echo ""
    read -p "  Choose [1 or 2]: " choice
    echo ""
    
    if [ "$choice" = "1" ]; then
        echo -e "  ${YELLOW}${BOLD}⚠️  WARNING:${NC} Proceeding without port 3000"
        echo -e "  ${RED}BigQuery OAuth will NOT work on this port!${NC}"
        echo ""
        read -p "  Enter port number [3001]: " PORT
        PORT=${PORT:-3001}
        echo -e "  ${GREEN}✓${NC} Will use port ${CYAN}${PORT}${NC}"
        # Update docker-compose port
        sed -i.bak "s/127.0.0.1:3000:3000/127.0.0.1:${PORT}:3000/" docker-compose.yml
        # Update NEXTAUTH_URL in .env if it exists
        if [ -f ".env" ]; then
            sed -i.bak "s|NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${PORT}|" .env
            rm -f .env.bak
        fi
    else
        echo -e "  ${CYAN}→${NC} Stop the service using port 3000 and run ${BOLD}./deploy.sh${NC} again"
        exit 0
    fi
else
    echo -e "  ${GREEN}${CHECK}${NC} Port 3000 is available"
    PORT=3000
fi

echo ""

# Generate configuration
echo -e "${BOLD}  ${WRENCH} Configuration${NC}"
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo -e "  ${GREEN}✓${NC} Found existing .env file"
    # Save PORT before sourcing .env to preserve port selection
    SELECTED_PORT=$PORT
    source .env
    # Restore PORT after sourcing
    PORT=$SELECTED_PORT
    
    # Check if ARKA_EVALUATION_KEY exists
    if [ -z "$ARKA_EVALUATION_KEY" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Missing ARKA_EVALUATION_KEY"
        echo ""
        echo -e "  ${BOLD}Arka requires an evaluation key to run.${NC}"
        echo -e "  ${DIM}Get your key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
        echo ""
        read -p "  Enter your ARKA_EVALUATION_KEY: " ARKA_EVALUATION_KEY
        echo ""
        
        # Validate format (UUID-like format with dashes)
        if [[ ! "$ARKA_EVALUATION_KEY" =~ ^[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}$ ]]; then
            echo -e "  ${RED}✗${NC} Invalid evaluation key format"
            echo -e "  ${DIM}Expected format: XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX${NC}"
            echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
            echo ""
            exit 1
        fi
        
        # Validate key with API
        echo -e "  ${DIM}→ Validating evaluation key...${NC}"
        VALIDATION_RESPONSE=$(curl -s "https://api.gumroad.com/v2/licenses/verify" \
            -d "product_id=xIqgG_9GR5uk0aSC5mhEUg==" \
            -d "license_key=${ARKA_EVALUATION_KEY}" | grep -o '"success":true')
        
        if [ -z "$VALIDATION_RESPONSE" ]; then
            echo -e "  ${RED}✗${NC} Invalid evaluation key"
            echo -e "  ${DIM}The key could not be validated. Please check your key.${NC}"
            echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
            echo ""
            exit 1
        fi
        echo -e "  ${GREEN}✓${NC} Evaluation key validated"
        
        # Add to .env file
        echo "" >> .env
        echo "# Arka Evaluation Key" >> .env
        echo "ARKA_EVALUATION_KEY=${ARKA_EVALUATION_KEY}" >> .env
        echo -e "  ${GREEN}✓${NC} Added ARKA_EVALUATION_KEY to .env"
    else
        # Ask user if they want to update the key
        echo ""
        echo -e "  ${BOLD}Current evaluation key:${NC} ${DIM}${ARKA_EVALUATION_KEY:0:8}-****-****-****${NC}"
        echo ""
        read -p "  Update evaluation key? (y/N): " UPDATE_KEY
        echo ""
        
        if [[ "$UPDATE_KEY" =~ ^[Yy]$ ]]; then
            echo -e "  ${BOLD}Enter new evaluation key${NC}"
            echo -e "  ${DIM}Get your key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
            echo ""
            read -p "  Enter your ARKA_EVALUATION_KEY: " NEW_ARKA_EVALUATION_KEY
            echo ""
            
            # Validate format
            if [[ ! "$NEW_ARKA_EVALUATION_KEY" =~ ^[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}$ ]]; then
                echo -e "  ${RED}✗${NC} Invalid evaluation key format"
                echo -e "  ${DIM}Expected format: XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX${NC}"
                echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
                echo ""
                exit 1
            fi
            
            # Validate key with API
            echo -e "  ${DIM}→ Validating evaluation key...${NC}"
            VALIDATION_RESPONSE=$(curl -s "https://api.gumroad.com/v2/licenses/verify" \
                -d "product_id=xIqgG_9GR5uk0aSC5mhEUg==" \
                -d "license_key=${NEW_ARKA_EVALUATION_KEY}" | grep -o '"success":true')
            
            if [ -z "$VALIDATION_RESPONSE" ]; then
                echo -e "  ${RED}✗${NC} Invalid evaluation key"
                echo -e "  ${DIM}The key could not be validated. Please check your key.${NC}"
                echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
                echo ""
                exit 1
            fi
            echo -e "  ${GREEN}✓${NC} Evaluation key validated"
            
            # Update .env file
            sed -i.bak "s/ARKA_EVALUATION_KEY=.*/ARKA_EVALUATION_KEY=${NEW_ARKA_EVALUATION_KEY}/" .env
            rm -f .env.bak
            echo -e "  ${GREEN}✓${NC} Updated ARKA_EVALUATION_KEY in .env"
            ARKA_EVALUATION_KEY=$NEW_ARKA_EVALUATION_KEY
        else
            # Validate existing key format
            if [[ ! "$ARKA_EVALUATION_KEY" =~ ^[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}$ ]]; then
                echo -e "  ${RED}✗${NC} Invalid evaluation key format in .env"
                echo -e "  ${DIM}Expected format: XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX${NC}"
                echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
                echo ""
                exit 1
            fi
            
            # Validate key with API
            echo -e "  ${DIM}→ Validating evaluation key...${NC}"
            VALIDATION_RESPONSE=$(curl -s "https://api.gumroad.com/v2/licenses/verify" \
                -d "product_id=xIqgG_9GR5uk0aSC5mhEUg==" \
                -d "license_key=${ARKA_EVALUATION_KEY}" | grep -o '"success":true')
            
            if [ -z "$VALIDATION_RESPONSE" ]; then
                echo -e "  ${RED}✗${NC} Invalid evaluation key"
                echo -e "  ${DIM}The key could not be validated. Please check your key.${NC}"
                echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
                echo ""
                exit 1
            fi
            echo -e "  ${GREEN}✓${NC} ARKA_EVALUATION_KEY found and validated"
        fi
    fi
else
    # Generate new configuration
    echo -e "  ${BOLD}Arka requires an evaluation key to run.${NC}"
    echo -e "  ${DIM}Get your key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
    echo ""
    read -p "  Enter your ARKA_EVALUATION_KEY: " ARKA_EVALUATION_KEY
    echo ""
    
    # Validate format (UUID-like format with dashes)
    if [[ ! "$ARKA_EVALUATION_KEY" =~ ^[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}-[A-F0-9]{8}$ ]]; then
        echo -e "  ${RED}✗${NC} Invalid evaluation key format"
        echo -e "  ${DIM}Expected format: XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX${NC}"
        echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
        echo ""
        exit 1
    fi
    
    # Validate key with API
    echo -e "  ${DIM}→ Validating evaluation key...${NC}"
    VALIDATION_RESPONSE=$(curl -s "https://api.gumroad.com/v2/licenses/verify" \
        -d "product_id=xIqgG_9GR5uk0aSC5mhEUg==" \
        -d "license_key=${ARKA_EVALUATION_KEY}" | grep -o '"success":true')
    
    if [ -z "$VALIDATION_RESPONSE" ]; then
        echo -e "  ${RED}✗${NC} Invalid evaluation key"
        echo -e "  ${DIM}The key could not be validated. Please check your key.${NC}"
        echo -e "  ${DIM}Get a valid key at ${CYAN}https://arunadev7.gumroad.com/l/arkaevaluate${NC}"
        echo ""
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} Evaluation key validated"
    
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    AUTH_SECRET=$(openssl rand -base64 32)
    DATA_SOURCE_ENCRYPTION_KEY=$(openssl rand -hex 32)
    OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)
    
    cat > .env << EOF
# Auto-generated configuration
# Generated on: $(date)

# Arka Evaluation Key (Required)
ARKA_EVALUATION_KEY=${ARKA_EVALUATION_KEY}

# Database
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Authentication
AUTH_SECRET=${AUTH_SECRET}
NEXTAUTH_URL=http://localhost:${PORT}

# Data Source Encryption
DATA_SOURCE_ENCRYPTION_KEY=${DATA_SOURCE_ENCRYPTION_KEY}

# OAuth Encryption
OAUTH_ENCRYPTION_KEY=${OAUTH_ENCRYPTION_KEY}

# Optional: AI Provider API Keys
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
XAI_API_KEY=

# Optional: S3 Storage
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=
EOF
    
    echo -e "  ${GREEN}✓${NC} Generated secure credentials"
    echo -e "  ${GREEN}✓${NC} Created .env file"
fi

echo ""
echo -e "  ${SPARKLES} ${BOLD}Ready to deploy!${NC}"
echo ""

# Pull and start services
echo -e "${BOLD}  ${PACKAGE} Deploying Arka${NC}"
echo ""

echo -e "  → Pulling Docker images..."
docker-compose pull

echo -e "  → Starting services..."
docker-compose up -d

echo -e "  → Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo -e "  ${BOLD}Service Status:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}╭─────────────────────────────────────────────────────────╮${NC}"
echo -e "${GREEN}│                                                         │${NC}"
echo -e "${GREEN}│  ${SPARKLES}  ${BOLD}Deployment Complete!${NC}${GREEN}                            │${NC}"
echo -e "${GREEN}│                                                         │${NC}"
echo -e "${GREEN}╰─────────────────────────────────────────────────────────╯${NC}"
echo ""
echo -e "  ${BOLD}Arka is now running!${NC}"
echo ""
echo -e "  🌐 Open in your browser:"
echo -e "     ${BOLD}${CYAN}http://localhost:${PORT}${NC}"
echo ""
echo -e "  ${DIM}Useful commands:${NC}"
echo -e "     ${DIM}./logs.sh       - View application logs${NC}"
echo -e "     ${DIM}./status.sh     - Check service status${NC}"
echo -e "     ${DIM}./stop.sh       - Stop Arka${NC}"
echo -e "     ${DIM}./terminate.sh  - Stop and remove all data${NC}"
echo ""
