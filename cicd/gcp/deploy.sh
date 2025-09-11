#!/bin/bash

# Google Cloud Run Deployment Script
# This script builds and deploys the webrtc-screen-share application to Google Cloud Run

set -e

# Configuration
SERVICE_NAME="ss"

# Get values from environment variables
PROJECT_ID="$GOOGLE_CLOUD_PROJECT"
REGION="$REGION"

# Validate required variables
if [ -z "$PROJECT_ID" ]; then
    echo "Error: GOOGLE_CLOUD_PROJECT environment variable must be set"
    echo "Usage: GOOGLE_CLOUD_PROJECT=your-project-id REGION=us-central1 ./deploy.sh"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "Error: REGION environment variable must be set"
    echo "Usage: GOOGLE_CLOUD_PROJECT=your-project-id REGION=us-central1 ./deploy.sh"
    exit 1
fi

echo "Deploying to Google Cloud Run..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"

# Set the project and quota project
gcloud config set project "$PROJECT_ID"
gcloud auth application-default set-quota-project "$PROJECT_ID"

# Ensure Cloud Build service account has required permissions
echo "Ensuring Cloud Build service account has required permissions..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
CLOUD_BUILD_SA="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"

# Grant required roles to Cloud Build service account
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$CLOUD_BUILD_SA" \
    --role="roles/run.admin" \
    --quiet 2>/dev/null || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$CLOUD_BUILD_SA" \
    --role="roles/iam.serviceAccountUser" \
    --quiet 2>/dev/null || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$CLOUD_BUILD_SA" \
    --role="roles/storage.admin" \
    --quiet 2>/dev/null || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$CLOUD_BUILD_SA" \
    --role="roles/artifactregistry.admin" \
    --quiet 2>/dev/null || true

# Enable required APIs
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --quiet 2>/dev/null || true

# Build and deploy to Cloud Run
echo "Building and deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --source . \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --platform=managed \
    --allow-unauthenticated \
    --port=8080 \
    --memory=1Gi \
    --cpu=1 \
    --max-instances=10 \
    --timeout=3600 \
    --concurrency=1000 \
    --cpu-throttling \
    --session-affinity \
    --set-env-vars="NODE_ENV=production"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --format="value(status.url)")

echo ""
echo "Deployment completed successfully!"
echo "Service URL: $SERVICE_URL"
echo ""
echo "You can test the deployment by visiting: $SERVICE_URL"
