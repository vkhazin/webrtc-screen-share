#!/bin/bash

# Quick Setup Verification
# Verifies that all CICD components are properly configured

echo "🚀 WebRTC Screen Share - Google Cloud Run CICD Setup"
echo "=================================================="
echo ""

# Check main.js for PORT environment variable
echo "🔍 Checking main.js for PORT environment variable..."
if grep -q "process.env.PORT" main.js; then
    echo "✅ main.js correctly uses process.env.PORT"
else
    echo "❌ main.js does not use process.env.PORT"
    exit 1
fi

# Check required files exist
echo ""
echo "🔍 Checking required files..."

REQUIRED_FILES=(
    "Dockerfile"
    ".dockerignore"
    "cicd/gcp/deploy.sh"
    "cicd/gcp/validate-env.sh"
    "cicd/gcp/create-gcp-sa.sh"
    "cicd/README.md"
    ".github/workflows/deploy-cloud-run.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
        exit 1
    fi
done

# Check script permissions
echo ""
echo "🔍 Checking script permissions..."

EXECUTABLE_FILES=(
    "cicd/gcp/deploy.sh"
    "cicd/gcp/validate-env.sh"
    "cicd/gcp/create-gcp-sa.sh"
)

for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -x "$file" ]; then
        echo "✅ $file is executable"
    else
        echo "❌ $file is not executable"
        exit 1
    fi
done

# Validate Dockerfile
echo ""
echo "🔍 Validating Dockerfile..."
if grep -q "CMD.*node.*main.js" Dockerfile; then
    echo "✅ Dockerfile correctly starts main.js"
else
    echo "❌ Dockerfile does not correctly start main.js"
    exit 1
fi

if grep -q "EXPOSE.*8080" Dockerfile; then
    echo "✅ Dockerfile exposes port 8080"
else
    echo "❌ Dockerfile does not expose port 8080"
    exit 1
fi

# Validate GitHub Actions workflow for correct environment variables
echo ""
echo "🔍 Validating GitHub Actions workflow environment variables..."
if grep -q "GOOGLE_CLOUD_PROJECT" .github/workflows/deploy-cloud-run.yml; then
    echo "✅ GitHub Actions uses GOOGLE_CLOUD_PROJECT"
else
    echo "❌ GitHub Actions does not use GOOGLE_CLOUD_PROJECT"
    exit 1
fi

if grep -q "vars.REGION" .github/workflows/deploy-cloud-run.yml; then
    echo "✅ GitHub Actions uses REGION variable"
else
    echo "❌ GitHub Actions does not use REGION variable"
    exit 1
fi

# Validate GitHub Actions workflow
echo ""
echo "🔍 Validating GitHub Actions workflow configuration..."
if grep -q "SERVICE_NAME.*ss" .github/workflows/deploy-cloud-run.yml; then
    echo "✅ GitHub Actions uses correct service name 'ss'"
else
    echo "❌ GitHub Actions does not use service name 'ss'"
    exit 1
fi

if grep -q "allow-unauthenticated" .github/workflows/deploy-cloud-run.yml; then
    echo "✅ GitHub Actions allows unauthenticated access"
else
    echo "❌ GitHub Actions does not allow unauthenticated access"
    exit 1
fi

echo ""
echo "🎉 All checks passed! CICD setup is complete."
echo ""
echo "Next steps:"
echo "1. Create service account: ./cicd/gcp/create-gcp-sa.sh"
echo "2. Run environment validation: ./cicd/gcp/validate-env.sh"
echo "3. Deploy locally: ./cicd/gcp/deploy.sh"
echo "4. Or configure GitHub Actions as described in cicd/README.md"