#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Emojis
ROCKET="🚀"
CHECK="✅"
CROSS="❌"
CLOUD="☁️"
KEY="🔑"
GEAR="⚙️"
SPARKLES="✨"
INFO="ℹ️"
WARNING="⚠️"
HOURGLASS="⏳"

# Default values
AWS_ACCOUNT="${AWS_ACCOUNT:-}"
AWS_REGION="${AWS_REGION:-us-west-2}"
ENDPOINT_NAME="${ENDPOINT_NAME:-}"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
ECR_IMAGE_URI="${ECR_IMAGE_URI:-634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:latest}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
SKIP_PROMPTS="${SKIP_PROMPTS:-false}"

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ROCKET} ${BOLD}${MAGENTA}Arka AWS Fargate Deployment${RESET}                       ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

log() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${CYAN}${INFO}${RESET}  $*"
}

success() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${GREEN}${CHECK}${RESET}  $*"
}

warning() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${YELLOW}${WARNING}${RESET}  $*"
}

error() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${RED}${CROSS}${RESET}  $*" >&2
    exit 1
}

step() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${MAGENTA}${GEAR}${RESET}  $*"
}

progress() {
    echo -e "${DIM}[$(date +'%H:%M:%S')]${RESET} ${YELLOW}${HOURGLASS}${RESET}  $*"
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}▶ $*${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

read_input() {
    local prompt_text="$1"
    local default_value="$2"
    local var_name="$3"
    
    if [ "$SKIP_PROMPTS" = "true" ]; then
        eval "$var_name=\"$default_value\""
        return
    fi
    
    if [ -n "$default_value" ]; then
        echo -ne "${BOLD}${CYAN}   $prompt_text${RESET} ${DIM}[${default_value}]${RESET}: "
    else
        echo -ne "${BOLD}${CYAN}   $prompt_text${RESET}: "
    fi
    
    read -r input
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        eval "$var_name=\"$default_value\""
    else
        eval "$var_name=\"$input\""
    fi
}

confirm() {
    if [ "$SKIP_PROMPTS" = "true" ]; then
        return 0
    fi
    
    echo -ne "${BOLD}${YELLOW}   $1 ${DIM}[y/N]${RESET}: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

show_usage() {
    cat << 'EOF'
Arka AWS Fargate Deployment

Deploys Arka to AWS using Fargate, RDS PostgreSQL, and Application Load Balancer.

Usage:
  ./deploy-fargate.sh [OPTIONS]

Required Options:
  --account-id ID              AWS account ID (12 digits)
  --endpoint-name NAME         Endpoint/subdomain name (e.g., 'arka' or 'chat')
  --anthropic-key KEY          Anthropic API key (sk-ant-...)

Optional Options:
  --region REGION              AWS region (default: us-west-2)
  --ecr-image URI              ECR image URI (default: shared repo)
  --domain-name DOMAIN         Custom domain (optional, e.g., chat.company.com)
  --hosted-zone-id ID          Route53 hosted zone ID (required with --domain-name)
  --skip-prompts               Non-interactive mode
  --help, -h                   Show this help

Examples:
  # Interactive mode
  ./deploy-fargate.sh

  # Quick deploy with AWS-generated URL
  ./deploy-fargate.sh --account-id 123456789012 --endpoint-name arka --anthropic-key sk-ant-...

  # Deploy with custom domain
  ./deploy-fargate.sh --account-id 123456789012 --endpoint-name chat \
     --anthropic-key sk-ant-... \
     --domain-name chat.company.com \
     --hosted-zone-id Z1234567890ABC

What Gets Created:
  • VPC with public/private subnets
  • ECS Fargate cluster and service
  • Application Load Balancer with HTTPS
  • RDS PostgreSQL database
  • S3 bucket for file uploads
  • AWS Secrets Manager for credentials

Cost Estimate:
  ~$100/month for minimal setup
  ~$300-500/month for production setup

Access Your Application:
  After deployment completes, the script will output:
  - Application URL (ALB DNS or custom domain)
  - Database endpoint
  - S3 bucket name

EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --account-id)
                AWS_ACCOUNT="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --endpoint-name)
                ENDPOINT_NAME="$2"
                shift 2
                ;;
            --anthropic-key)
                ANTHROPIC_API_KEY="$2"
                shift 2
                ;;
            --ecr-image)
                ECR_IMAGE_URI="$2"
                shift 2
                ;;
            --domain-name)
                DOMAIN_NAME="$2"
                shift 2
                ;;
            --hosted-zone-id)
                HOSTED_ZONE_ID="$2"
                shift 2
                ;;
            --skip-prompts)
                SKIP_PROMPTS="true"
                shift
                ;;
            --help|-h)
                show_usage
                ;;
            *)
                error "Unknown option: $1\nUse --help for usage information"
                ;;
        esac
    done
}

interactive_setup() {
    if [ "$SKIP_PROMPTS" = "true" ]; then
        return
    fi
    
    print_section "Interactive Setup"
    
    echo -e "${BOLD}${CYAN}Let's configure your Arka deployment on AWS Fargate!${RESET}"
    echo ""
    
    # AWS Configuration
    echo -e "${BOLD}${CYAN}❓ AWS Configuration${RESET}"
    if [ -z "$AWS_ACCOUNT" ]; then
        step "Finding your AWS account ID..."
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
        if [ -n "$AWS_ACCOUNT" ]; then
            log "Detected account: $AWS_ACCOUNT"
        fi
    fi
    read_input "AWS Account ID" "$AWS_ACCOUNT" AWS_ACCOUNT
    read_input "AWS Region" "$AWS_REGION" AWS_REGION
    echo ""
    
    # Endpoint Name
    echo -e "${BOLD}${CYAN}❓ Endpoint Configuration${RESET}"
    echo -e "${DIM}   This will be used for resource naming and as a subdomain prefix${RESET}"
    echo -e "${DIM}   Examples: 'arka', 'chat', 'ai-assistant'${RESET}"
    read_input "Endpoint Name" "${ENDPOINT_NAME:-arka}" ENDPOINT_NAME
    echo ""
    
    # API Key
    echo -e "${BOLD}${CYAN}❓ Anthropic API Key${RESET}"
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        read_input "Anthropic API Key (sk-ant-...)" "" ANTHROPIC_API_KEY
    else
        echo -e "   ${GREEN}✓${RESET} Anthropic API key already set"
    fi
    echo ""
    
    # Custom Domain
    echo -e "${BOLD}${CYAN}❓ Custom Domain (Optional)${RESET}"
    echo -e "${DIM}   Leave blank to use AWS-generated ALB URL${RESET}"
    echo ""
    if confirm "Configure custom domain (e.g., chat.company.com)?"; then
        echo ""
        read_input "Domain Name" "$DOMAIN_NAME" DOMAIN_NAME
        read_input "Route53 Hosted Zone ID" "$HOSTED_ZONE_ID" HOSTED_ZONE_ID
    fi
    echo ""
    
    # Advanced Options
    if confirm "Configure advanced options (ECR image, instance sizes)?"; then
        echo ""
        read_input "ECR Image URI" "$ECR_IMAGE_URI" ECR_IMAGE_URI
        echo ""
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    step "Checking for AWS CLI..."
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not found. Install: https://aws.amazon.com/cli/"
    fi
    success "AWS CLI found"
    
    step "Checking for Node.js..."
    if ! command -v node &> /dev/null; then
        error "Node.js not found. Install: https://nodejs.org/"
    fi
    success "Node.js $(node --version) found"
    
    step "Checking for npm..."
    if ! command -v npm &> /dev/null; then
        error "npm not found. Install Node.js from https://nodejs.org/"
    fi
    success "npm found"
    
    step "Validating AWS account ID..."
    if [ -z "$AWS_ACCOUNT" ]; then
        error "AWS account ID is required"
    fi
    if ! [[ "$AWS_ACCOUNT" =~ ^[0-9]{12}$ ]]; then
        error "Invalid AWS account ID format (must be 12 digits)"
    fi
    success "AWS account: $AWS_ACCOUNT"
    
    step "Validating endpoint name..."
    if [ -z "$ENDPOINT_NAME" ]; then
        error "Endpoint name is required"
    fi
    if ! [[ "$ENDPOINT_NAME" =~ ^[a-z0-9-]+$ ]]; then
        error "Invalid endpoint name (use lowercase letters, numbers, and hyphens only)"
    fi
    success "Endpoint name: $ENDPOINT_NAME"
    
    step "Validating Anthropic API key..."
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        error "Anthropic API key is required"
    fi
    success "Anthropic API key configured"
    
    if [ -n "$DOMAIN_NAME" ] && [ -z "$HOSTED_ZONE_ID" ]; then
        error "Hosted Zone ID is required when using custom domain"
    fi
    
    step "Checking AWS credentials..."
    if ! aws sts get-caller-identity --region "$AWS_REGION" &>/dev/null; then
        error "AWS credentials not configured or invalid. Run: aws configure"
    fi
    local current_account=$(aws sts get-caller-identity --query Account --output text)
    if [ "$current_account" != "$AWS_ACCOUNT" ]; then
        warning "Current AWS account ($current_account) differs from specified account ($AWS_ACCOUNT)"
        if ! confirm "Continue anyway?"; then
            error "Deployment cancelled"
        fi
    fi
    success "AWS credentials validated"
    
    success "All prerequisites met ${SPARKLES}"
}

show_configuration() {
    print_section "📋 Deployment Configuration"
    
    echo -e "  ${BOLD}AWS Account:${RESET}     ${AWS_ACCOUNT}"
    echo -e "  ${BOLD}AWS Region:${RESET}      ${AWS_REGION}"
    echo -e "  ${BOLD}Endpoint Name:${RESET}   ${ENDPOINT_NAME}"
    echo -e "  ${BOLD}ECR Image:${RESET}       ${ECR_IMAGE_URI}"
    echo -e "  ${BOLD}Stack Name:${RESET}      ${ENDPOINT_NAME}-stack"
    
    if [ -n "$DOMAIN_NAME" ]; then
        echo -e "  ${BOLD}Custom Domain:${RESET}   ${GREEN}${DOMAIN_NAME}${RESET}"
        echo -e "  ${BOLD}Hosted Zone:${RESET}     ${HOSTED_ZONE_ID}"
    else
        echo -e "  ${BOLD}Custom Domain:${RESET}   ${DIM}Not configured (will use ALB URL)${RESET}"
    fi
    
    echo ""
    echo -e "${BOLD}${CYAN}📦 Resources to be created:${RESET}"
    echo -e "  • VPC with public/private subnets (2 AZs)"
    echo -e "  • ECS Fargate cluster and service (2 tasks)"
    echo -e "  • Application Load Balancer (internet-facing)"
    echo -e "  • RDS PostgreSQL database (db.t4g.small)"
    echo -e "  • S3 bucket: ${ENDPOINT_NAME}-uploads-${AWS_ACCOUNT}"
    echo -e "  • CloudWatch Logs groups"
    echo -e "  • Secrets Manager secrets"
    if [ -n "$DOMAIN_NAME" ]; then
        echo -e "  • ACM Certificate for ${DOMAIN_NAME}"
        echo -e "  • Route53 A record"
    fi
    echo ""
    
    echo -e "${BOLD}${YELLOW}💰 Estimated Monthly Cost: ~\$50-100${RESET}"
    echo ""
    
    if [ "$SKIP_PROMPTS" != "true" ]; then
        if ! confirm "Proceed with deployment?"; then
            echo ""
            warning "Deployment cancelled by user"
            exit 0
        fi
    fi
}

install_dependencies() {
    print_section "Installing CDK Dependencies"
    
    cd "$SCRIPT_DIR"
    
    if [ ! -d "node_modules" ]; then
        step "Installing npm packages..."
        npm install --quiet
        success "Dependencies installed"
    else
        success "Dependencies already installed"
    fi
}

bootstrap_cdk() {
    print_section "Bootstrapping AWS CDK"
    
    step "Checking if CDK is bootstrapped in ${AWS_REGION}..."
    
    if ! aws cloudformation describe-stacks \
        --stack-name CDKToolkit \
        --region "$AWS_REGION" &>/dev/null; then
        
        progress "Bootstrapping CDK (first-time setup, takes ~2 minutes)..."
        npm run cdk bootstrap \
            "aws://${AWS_ACCOUNT}/${AWS_REGION}" \
            --region "$AWS_REGION"
        success "CDK bootstrapped successfully"
    else
        success "CDK already bootstrapped"
    fi
}

deploy_stack() {
    print_section "Deploying Arka Stack"
    
    cd "$SCRIPT_DIR"
    
    export CDK_DEFAULT_ACCOUNT="$AWS_ACCOUNT"
    export CDK_DEFAULT_REGION="$AWS_REGION"
    export ENDPOINT_NAME="$ENDPOINT_NAME"
    export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
    export ECR_IMAGE_URI="$ECR_IMAGE_URI"
    
    if [ -n "$DOMAIN_NAME" ]; then
        export DOMAIN_NAME="$DOMAIN_NAME"
        export HOSTED_ZONE_ID="$HOSTED_ZONE_ID"
    fi
    
    progress "Synthesizing CDK stack..."
    npm run synth --quiet
    success "Stack synthesized"
    
    progress "Deploying to AWS (this takes 10-15 minutes)..."
    echo ""
    echo -e "${DIM}Creating resources:${RESET}"
    echo -e "${DIM}  [1/7] VPC and networking...${RESET}"
    echo -e "${DIM}  [2/7] Security groups...${RESET}"
    echo -e "${DIM}  [3/7] RDS database...${RESET}"
    echo -e "${DIM}  [4/7] S3 bucket...${RESET}"
    echo -e "${DIM}  [5/7] ECS cluster and task definition...${RESET}"
    echo -e "${DIM}  [6/7] Application Load Balancer...${RESET}"
    echo -e "${DIM}  [7/7] Fargate service...${RESET}"
    echo ""
    
    npm run deploy -- --require-approval never
    
    success "Stack deployed successfully! ${SPARKLES}"
}

show_outputs() {
    print_section "📊 Deployment Complete!"
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${SPARKLES} ${BOLD}Arka is now running on AWS!${RESET}                        ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    step "Fetching stack outputs..."
    local stack_name="${ENDPOINT_NAME}-stack"
    
    local app_url=$(aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='ApplicationURL'].OutputValue" \
        --output text 2>/dev/null || echo "")
    
    local alb_dns=$(aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
        --output text 2>/dev/null || echo "")
    
    local db_endpoint=$(aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" \
        --output text 2>/dev/null || echo "")
    
    echo -e "${BOLD}${CYAN}🌐 Access Your Application${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
    if [ -n "$DOMAIN_NAME" ]; then
        echo -e "  ${BOLD}Custom URL:${RESET}      ${GREEN}${BOLD}https://${DOMAIN_NAME}${RESET}"
        echo -e "  ${DIM}(SSL certificate may take a few minutes to validate)${RESET}"
    fi
    echo -e "  ${BOLD}ALB URL:${RESET}         ${CYAN}${app_url}${RESET}"
    echo -e "  ${DIM}${alb_dns}${RESET}"
    echo ""
    
    echo -e "${BOLD}${CYAN}📊 Infrastructure Details${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
    echo -e "  ${BOLD}AWS Region:${RESET}      ${AWS_REGION}"
    echo -e "  ${BOLD}Stack Name:${RESET}      ${stack_name}"
    echo -e "  ${BOLD}Database:${RESET}        ${db_endpoint}"
    echo -e "  ${BOLD}S3 Bucket:${RESET}       ${ENDPOINT_NAME}-uploads-${AWS_ACCOUNT}"
    echo ""
    
    echo -e "${BOLD}${CYAN}🔧 Management Commands${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
    echo -e "  ${BOLD}View logs:${RESET}"
    echo -e "  ${DIM}aws logs tail /ecs/${ENDPOINT_NAME}-service --follow --region ${AWS_REGION}${RESET}"
    echo ""
    echo -e "  ${BOLD}Update service:${RESET}"
    echo -e "  ${DIM}./deploy-fargate.sh --account-id ${AWS_ACCOUNT} --endpoint-name ${ENDPOINT_NAME} \\${RESET}"
    echo -e "  ${DIM}  --anthropic-key \$ANTHROPIC_API_KEY --ecr-image <new-image>${RESET}"
    echo ""
    echo -e "  ${BOLD}Delete stack:${RESET}"
    echo -e "  ${DIM}cd scripts/aws-fargate-deployment && npm run destroy${RESET}"
    echo ""
    
    echo -e "${BOLD}${YELLOW}⏳ Please wait 2-3 minutes for services to fully start${RESET}"
    echo ""
}

main() {
    parse_arguments "$@"
    
    print_header
    
    interactive_setup
    
    show_configuration
    
    check_prerequisites
    
    install_dependencies
    
    bootstrap_cdk
    
    deploy_stack
    
    show_outputs
    
    echo -e "${BOLD}${GREEN}🎉 Deployment complete! Enjoy using Arka!${RESET}"
    echo ""
}

main "$@"
