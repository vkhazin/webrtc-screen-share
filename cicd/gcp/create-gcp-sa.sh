#!/bin/bash

# Google Cloud Service Account Creation Script for GitHub Actions
# This script creates a service account for GitHub Actions deployment to Cloud Run
# Must be executed by a user who is interactively logged in to gcloud

set -e

# Configuration
SA_NAME="github-actions-cloud-run"
SA_DISPLAY_NAME="GitHub Actions Cloud Run Deployment"
SA_DESCRIPTION="Service account for deploying to Cloud Run via GitHub Actions"
SECRET_DIR="./.secret"
KEY_FILE="$SECRET_DIR/gcp-github-actions-key.json"

echo "🔧 Creating Google Cloud Service Account for GitHub Actions..."
echo ""

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "   Please install Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated with Google Cloud"
    echo "   Please run: gcloud auth login"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No default project set"
    echo "   Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "✅ Using project: $PROJECT_ID"
echo "✅ Authenticated as: $(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)"
echo ""

# Create the service account
echo "🔧 Creating service account: $SA_NAME"
if gcloud iam service-accounts describe "$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" &>/dev/null; then
    echo "⚠️  Service account $SA_NAME already exists, skipping creation"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="$SA_DISPLAY_NAME" \
        --description="$SA_DESCRIPTION"
    echo "✅ Service account created"
fi

# Define required roles
REQUIRED_ROLES=(
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
    "roles/artifactregistry.admin"
    "roles/cloudbuild.builds.builder"
)

# Assign roles to the service account
echo ""
echo "🔧 Assigning IAM roles..."
for role in "${REQUIRED_ROLES[@]}"; do
    echo "   Adding role: $role"
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="$role" \
        --quiet
done
echo "✅ All required roles assigned"

# Create secret directory if it doesn't exist
echo ""
echo "🔧 Creating secret directory..."
mkdir -p "$SECRET_DIR"
echo "✅ Secret directory created: $SECRET_DIR"

# Generate and download service account key
echo ""
echo "🔧 Generating service account key..."
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "✅ Service account key saved to: $KEY_FILE"

# Set appropriate permissions on the key file
chmod 600 "$KEY_FILE"

echo ""
echo "🎉 Service account setup completed successfully!"
echo ""
echo "📋 Next steps for GitHub Actions setup:"
echo "   1. Copy the contents of: $KEY_FILE"
echo "   2. In your GitHub repository, go to Settings > Secrets and variables > Actions"
echo "   3. Create a new secret named: GOOGLE_CREDENTIALS"
echo "   4. Paste the JSON key content as the secret value"
echo "   5. Set repository variables:"
echo "      - GOOGLE_CLOUD_PROJECT: $PROJECT_ID"
echo "      - REGION: us-central1 (or your preferred region)"
echo ""
echo "📁 Service Account Details:"
echo "   Name: $SA_NAME"
echo "   Email: $SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "   Project: $PROJECT_ID"
echo "   Key File: $KEY_FILE"
echo ""
echo "⚠️  Important Security Notes:"
echo "   - The key file contains sensitive credentials"
echo "   - Never commit the .secret directory to version control"
echo "   - The .secret directory is already excluded in .gitignore"
echo "   - Consider rotating the key periodically for security"