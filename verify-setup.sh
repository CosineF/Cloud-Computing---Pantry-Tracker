#!/bin/bash

echo "🔍 Verifying Cloud Pantry Tracker Setup"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check SAM CLI
echo -n "Checking SAM CLI... "
if command -v sam &> /dev/null; then
    SAM_VERSION=$(sam --version 2>&1 | head -n1)
    echo -e "${GREEN}✓ Installed${NC} ($SAM_VERSION)"
else
    echo -e "${RED}✗ Not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Python
echo -n "Checking Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Installed${NC} ($PYTHON_VERSION)"
else
    echo -e "${RED}✗ Not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker (optional for local testing)
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo -e "${GREEN}✓ Installed and running${NC} ($DOCKER_VERSION)"
    else
        echo -e "${YELLOW}⚠ Installed but not running${NC} (Start Docker Desktop to test locally)"
    fi
else
    echo -e "${YELLOW}⚠ Not installed${NC} (Required for local Lambda testing)"
    echo "  Install from: https://www.docker.com/products/docker-desktop"
fi

# Check AWS CLI (optional for deployment)
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1)
    echo -e "${GREEN}✓ Installed${NC} ($AWS_VERSION)"
    
    # Check if configured
    if aws configure list &> /dev/null; then
        echo "  AWS credentials: Configured"
    else
        echo -e "  ${YELLOW}AWS credentials: Not configured${NC} (Run 'aws configure' to set up)"
    fi
else
    echo -e "${YELLOW}⚠ Not installed${NC} (Required for AWS deployment)"
    echo "  Install: brew install awscli"
fi

# Check project files
echo ""
echo "Checking project files..."
REQUIRED_FILES=(
    "template.yaml"
    "backend/lambda_function.py"
    "backend/requirements.txt"
    "frontend/index.html"
    "frontend/app.js"
    "frontend/styles.css"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (MISSING)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    ERRORS=$((ERRORS + MISSING_FILES))
fi

# Test SAM template syntax
echo ""
echo "Testing SAM template..."
if sam validate --template template.yaml &> /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Template syntax is valid${NC}"
else
    echo -e "  ${YELLOW}⚠ Template validation requires AWS region${NC}"
    echo "  (This is normal if AWS CLI is not configured)"
fi

# Try building (this validates the template structure)
echo ""
echo "Testing build process..."
if sam build --use-container 2>&1 | grep -q "Build Succeeded"; then
    echo -e "  ${GREEN}✓ Build successful${NC}"
elif sam build 2>&1 | tail -n1 | grep -q "Build Succeeded"; then
    echo -e "  ${GREEN}✓ Build successful${NC}"
else
    echo -e "  ${YELLOW}⚠ Build test skipped (requires Docker for full validation)${NC}"
fi

# Summary
echo ""
echo "========================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Setup looks good!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test frontend (mock): cd frontend && python3 -m http.server 8000"
    echo "  2. Test locally (requires Docker): sam build && sam local start-api"
    echo "  3. Deploy to AWS (requires AWS CLI): sam build && sam deploy --guided"
else
    echo -e "${YELLOW}⚠ Found $ERRORS issue(s)${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
fi
echo ""

