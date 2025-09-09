#!/bin/bash

# Google Cloud Run Deployment Script
# This script builds and deploys the webrtc-screen-share application to Google Cloud Run

set -e

# Configuration
SERVICE_NAME="ss"
DEFAULT_REGION="us-central1"
DEFAULT_PROJECT_ID=""

# Get values from environment variables or use defaults
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$DEFAULT_PROJECT_ID}"
REGION="${REGION:-$DEFAULT_REGION}"

# Validate required variables
if [ -z "$PROJECT_ID" ]; then
    echo "Error: GOOGLE_CLOUD_PROJECT environment variable must be set"
    echo "Usage: GOOGLE_CLOUD_PROJECT=your-project-id REGION=us-central1 ./deploy.sh"
    exit 1
fi

echo "Deploying to Google Cloud Run..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"

# Set the project
gcloud config set project "$PROJECT_ID"

# Build and deploy to Cloud Run
echo "Building and deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --source . \
    --region="$REGION" \
    --platform=managed \
    --allow-unauthenticated \
    --port=8080 \
    --memory=512Mi \
    --cpu=1 \
    --max-instances=10 \
    --timeout=3600 \
    --set-env-vars="NODE_ENV=production"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")

echo ""
echo "Deployment completed successfully!"
echo "Service URL: $SERVICE_URL"
echo ""
echo "You can test the deployment by visiting: $SERVICE_URL"