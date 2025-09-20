#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

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

cat << 'BANNER'
    _    ___ ____  ___   ____                      _ _         
   / \  |_ _/ ___|_ _|  / ___|  ___  ___ _   _ _ __(_) |_ _   _ 
  / _ \  | |\___ \| |   \___ \ / _ \/ __| | | | '__| | __| | | |
 / ___ \ | | ___) | |    ___) |  __/ (__| |_| | |  | | |_| |_| |
/_/   \_\___|____/___|  |____/ \___|\___|\__,_|_|  |_|\__|\__, |
                                                          |___/ 
    ____                  _ _            
   | __ )  __ _ ___  ___  | (_)_ __   ___ 
   |  _ \ / _` / __|/ _ \ | | | '_ \ / _ \
   | |_) | (_| \__ \  __/ | | | | | |  __/
   |____/ \__,_|___/\___| |_|_|_| |_|\___|
BANNER

log "🚀 AISI AWS Security Baseline Deployment"
log "========================================"

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    error "Please run this script from the repository root directory"
fi

# Validate prerequisites
log "📋 Validating prerequisites..."
if [ ! -f "scripts/validate.sh" ]; then
    error "Validation script not found"
fi

./scripts/validate.sh

# Check for Terraform variables
if [ ! -f "terraform.tfvars" ]; then
    if [ -f "terraform/terraform.tfvars.example" ]; then
        warning "terraform.tfvars not found. Copying from example..."
        cp terraform/terraform.tfvars.example terraform.tfvars
        warning "Please edit terraform.tfvars with your account details before continuing"
        echo "Press Enter when ready to continue..."
        read -r
    else
        error "terraform.tfvars not found and no example available"
    fi
fi

# Initialize Terraform
log "🔧 Initializing Terraform..."
cd terraform/
terraform init

# Terraform plan
log "📝 Creating deployment plan..."
terraform plan -var-file="../terraform.tfvars" -out=tfplan

# Confirm deployment
echo ""
log "🤔 Ready to deploy AISI Security Baseline?"
warning "This will create security resources in your AWS account."
echo -e "Type ${GREEN}'yes'${NC} to continue, or anything else to cancel:"
read -r response

if [[ "$response" != "yes" ]]; then
    log "❌ Deployment cancelled by user"
    rm -f tfplan
    exit 0
fi

# Deploy
log "🏗️  Deploying security baseline..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Get outputs
log "📤 Deployment Outputs:"
echo "=================================================="
terraform output
echo "=================================================="

success "🎉 AISI Security Baseline deployment completed! 🚀"
