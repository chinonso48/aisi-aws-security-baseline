#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

log() {
    echo -e "${BLUE}🔍 $1${NC}"
}

echo "🔍 AISI Security Baseline - Environment Validation"
echo "=================================================="

# Check AWS CLI
log "Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    error "AWS CLI not found. Please install AWS CLI v2"
fi
success "AWS CLI found: $(aws --version | head -n1)"

# Check AWS credentials
log "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS credentials not configured. Run 'aws configure' first"
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
success "AWS credentials valid for account: $ACCOUNT_ID"

# Check Terraform
log "Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    error "Terraform not found. Please install Terraform >= 1.0"
fi
success "Terraform found: $(terraform version | head -n1)"

# Check for configuration files
log "Checking configuration files..."
if [ ! -f "terraform.tfvars" ]; then
    if [ ! -f "terraform/terraform.tfvars.example" ]; then
        error "No terraform.tfvars found and no example available"
    else
        warning "terraform.tfvars not found. Example available at terraform/terraform.tfvars.example"
    fi
else
    success "terraform.tfvars found"
fi

# Check Terraform syntax
log "Validating Terraform syntax..."
cd terraform/ 2>/dev/null || error "terraform/ directory not found"
if terraform validate &> /dev/null; then
    success "Terraform configuration is valid"
else
    error "Terraform validation failed. Check your .tf files"
fi
cd .. || exit 1

success "✅ Environment validation completed successfully!"
echo "Ready to deploy with: ./scripts/deploy.sh"
