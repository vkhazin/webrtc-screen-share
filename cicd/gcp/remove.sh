#!/bin/bash

# Google Cloud Run Removal Script
# This script removes the webrtc-screen-share application and associated resources from Google Cloud Run

set -e

# Configuration (must match deploy.sh)
SERVICE_NAME="ss"

# Get values from environment variables
PROJECT_ID="$GOOGLE_CLOUD_PROJECT"
REGION="$REGION"

# Validate required variables
if [ -z "$PROJECT_ID" ]; then
    echo "Error: GOOGLE_CLOUD_PROJECT environment variable must be set"
    echo "Usage: GOOGLE_CLOUD_PROJECT=your-project-id REGION=us-central1 ./remove.sh"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "Error: REGION environment variable must be set"
    echo "Usage: GOOGLE_CLOUD_PROJECT=your-project-id REGION=us-central1 ./remove.sh"
    exit 1
fi

echo "Removing resources from Google Cloud..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"

# Set the project
gcloud config set project "$PROJECT_ID"

# Check if the Cloud Run service exists before attempting to delete it
if gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --quiet >/dev/null 2>&1; then
    echo "Deleting Cloud Run service: $SERVICE_NAME"
    gcloud run services delete "$SERVICE_NAME" \
        --project="$PROJECT_ID" \
        --region="$REGION" \
        --quiet
    echo "Cloud Run service deleted successfully."
else
    echo "Cloud Run service '$SERVICE_NAME' not found in region '$REGION'."
fi

# Remove IAM policy bindings for Cloud Build service account
echo "Removing IAM policy bindings for Cloud Build service account..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null || echo "")

if [ -n "$PROJECT_NUMBER" ]; then
    CLOUD_BUILD_SA="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
    
    # Remove IAM policy bindings (ignore errors if they don't exist)
    echo "Removing roles/run.admin binding..."
    gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$CLOUD_BUILD_SA" \
        --role="roles/run.admin" \
        --quiet 2>/dev/null || echo "  Role binding not found or already removed"
    
    echo "Removing roles/iam.serviceAccountUser binding..."
    gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$CLOUD_BUILD_SA" \
        --role="roles/iam.serviceAccountUser" \
        --quiet 2>/dev/null || echo "  Role binding not found or already removed"
    
    echo "Removing roles/storage.admin binding..."
    gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$CLOUD_BUILD_SA" \
        --role="roles/storage.admin" \
        --quiet 2>/dev/null || echo "  Role binding not found or already removed"
    
    echo "Removing roles/artifactregistry.admin binding..."
    gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$CLOUD_BUILD_SA" \
        --role="roles/artifactregistry.admin" \
        --quiet 2>/dev/null || echo "  Role binding not found or already removed"
else
    echo "Warning: Could not retrieve project number. Skipping IAM policy cleanup."
fi

# Note about APIs - we don't disable them as they might be used by other services
echo ""
echo "Note: Google Cloud APIs (run.googleapis.com, cloudbuild.googleapis.com, artifactregistry.googleapis.com)"
echo "are not disabled as they might be used by other services in your project."
echo "You can manually disable them if needed using:"
echo "  gcloud services disable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com"

# Note about Container Registry/Artifact Registry images
echo ""
echo "Note: Container images stored in Artifact Registry or Container Registry are not automatically deleted."
echo "You may want to clean them up manually to avoid storage costs:"
echo "  gcloud artifacts repositories list"
echo "  gcloud container images list"

echo ""
echo "Cleanup completed successfully!"
echo "All deployed resources for service '$SERVICE_NAME' have been removed."
