#!/bin/bash

# Environment Validation Script
# Checks if the environment is properly configured for Google Cloud Run deployment

set -e

echo "🔍 Validating environment for Google Cloud Run deployment..."
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "   Please install Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
else
    echo "✅ gcloud CLI is installed"
    gcloud version --format="value(google-cloud-sdk.version)" | head -1 | sed 's/^/   Version: /'
fi

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated with Google Cloud"
    echo "   Please run: gcloud auth login"
    exit 1
else
    echo "✅ Authenticated with Google Cloud"
    gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 | sed 's/^/   Account: /'
fi

# Check if project is set
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No default project set"
    echo "   Please run: gcloud config set project YOUR_PROJECT_ID"
    echo "   Or set the GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
else
    echo "✅ Default project configured"
    echo "   Project: $PROJECT_ID"
fi

# Check required APIs
echo ""
echo "🔍 Checking required APIs..."

REQUIRED_APIS=(
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "artifactregistry.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        echo "✅ $api is enabled"
    else
        echo "⚠️  $api is not enabled"
        echo "   Enable with: gcloud services enable $api"
    fi
done

# Check Cloud Run permissions
echo ""
echo "🔍 Checking Cloud Run permissions..."

if gcloud run services list --region=us-central1 &>/dev/null; then
    echo "✅ Cloud Run permissions are configured"
else
    echo "❌ Insufficient Cloud Run permissions"
    echo "   Ensure you have the 'Cloud Run Admin' role"
fi

# Check Docker (for local builds)
echo ""
echo "🔍 Checking Docker..."

if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    docker --version | sed 's/^/   /'
    
    if docker info &>/dev/null; then
        echo "✅ Docker daemon is running"
    else
        echo "⚠️  Docker daemon is not running"
        echo "   Please start Docker"
    fi
else
    echo "ℹ️  Docker not found (optional for Cloud Run source deployment)"
fi

# Validate environment variables for script usage
echo ""
echo "🔍 Environment variables for deployment script..."

if [ -n "${GOOGLE_CLOUD_PROJECT:-}" ]; then
    echo "✅ GOOGLE_CLOUD_PROJECT is set: $GOOGLE_CLOUD_PROJECT"
else
    echo "ℹ️  GOOGLE_CLOUD_PROJECT not set (will use default project: $PROJECT_ID)"
fi

if [ -n "${REGION:-}" ]; then
    echo "✅ REGION is set: $REGION"
else
    echo "ℹ️  REGION not set (will use default: us-central1)"
fi

echo ""
echo "🎉 Environment validation completed!"
echo ""
echo "To deploy the application:"
echo "   ./cicd/gcp/deploy.sh"
echo ""
echo "Or with custom settings:"
echo "   GOOGLE_CLOUD_PROJECT=your-project REGION=us-west1 ./cicd/gcp/deploy.sh"