# CICD Setup for Google Cloud Run

This directory contains the continuous integration and deployment (CICD) configuration for deploying the webrtc-screen-share application to Google Cloud Run.

## Overview

The application is deployed as a containerized service on Google Cloud Run with the following characteristics:
- **Service Name**: `ss` (neutral name to avoid detection)
- **Access**: Anonymous/unauthenticated access allowed
- **Platform**: Google Cloud Run (fully managed)
- **Container**: Node.js 18 with minimal dependencies

## Prerequisites

### For Local Deployment

1. **Google Cloud CLI**: Install and configure the [gcloud CLI](https://cloud.google.com/sdk/docs/install)
2. **Authentication**: Run `gcloud auth login` to authenticate with your Google Cloud account
3. **Docker**: Ensure Docker is installed (used by Cloud Run for building)
4. **Required Permissions**: Your account needs the following IAM roles:
   - Cloud Run Admin
   - Service Account User
   - Storage Admin (for container registry)

### For GitHub Actions

1. **Service Account**: Create a Google Cloud service account with the following roles:
   - Cloud Run Admin
   - Service Account User
   - Storage Admin
   - Artifact Registry Admin (if using Artifact Registry)

2. **GitHub Secrets**: Configure the following in your GitHub repository:
   - `GCP_CREDENTIALS`: JSON key for your service account

3. **GitHub Variables**: Configure the following repository variables:
   - `GCP_PROJECT_ID`: Your Google Cloud project ID
   - `GCP_REGION`: Target deployment region (e.g., `us-central1`)

## Local Deployment

### Quick Deploy

```bash
# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"

# Run deployment script
./cicd/gcp/deploy.sh
```

### Manual Deployment

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Deploy to Cloud Run
gcloud run deploy ss \
  --source . \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --max-instances=10
```

## GitHub Actions Deployment

### Setup Steps

1. **Create Service Account**:
   ```bash
   # Create service account
   gcloud iam service-accounts create github-actions-sa \
     --display-name="GitHub Actions Service Account"

   # Get the email
   SA_EMAIL=$(gcloud iam service-accounts list \
     --filter="displayName:GitHub Actions Service Account" \
     --format="value(email)")

   # Grant necessary roles
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:$SA_EMAIL" \
     --role="roles/run.admin"

   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:$SA_EMAIL" \
     --role="roles/iam.serviceAccountUser"

   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:$SA_EMAIL" \
     --role="roles/storage.admin"

   # Create and download key
   gcloud iam service-accounts keys create key.json \
     --iam-account=$SA_EMAIL
   ```

2. **Configure GitHub Repository**:
   - Go to your repository settings → Secrets and variables → Actions
   - Add the following secret:
     - `GCP_CREDENTIALS`: Contents of the `key.json` file
   - Add the following variables:
     - `GCP_PROJECT_ID`: Your Google Cloud project ID
     - `GCP_REGION`: Your preferred region (e.g., `us-central1`)

3. **Trigger Deployment**:
   - Push to `main` branch for automatic deployment
   - Or manually trigger via GitHub Actions tab

### Workflow Features

- **Automatic Deployment**: Triggers on push to main branch
- **Manual Deployment**: Can be triggered manually with environment selection
- **Dependency Caching**: npm dependencies are cached for faster builds
- **Security**: Uses workload identity federation for secure authentication
- **Monitoring**: Outputs deployment URL and status

## Configuration

### Service Configuration

The Cloud Run service is configured with:
- **CPU**: 1 vCPU
- **Memory**: 512Mi
- **Max Instances**: 10 (auto-scaling)
- **Timeout**: 3600 seconds (1 hour)
- **Port**: 8080 (standard Cloud Run port)
- **Access**: Unauthenticated (public access)

### Environment Variables

The application automatically uses the following environment variables:
- `PORT`: Provided by Cloud Run (typically 8080)
- `NODE_ENV`: Set to "production" in deployment

### Custom Configuration

To modify the deployment configuration, edit:
- **Local deployment**: `cicd/gcp/deploy.sh`
- **GitHub Actions**: `.github/workflows/deploy-cloud-run.yml`
- **Container**: `Dockerfile`

## Monitoring and Logs

### View Logs
```bash
# View recent logs
gcloud run logs read ss --region=us-central1

# Follow logs in real-time
gcloud run logs tail ss --region=us-central1
```

### Monitor Service
```bash
# Get service details
gcloud run services describe ss --region=us-central1

# List all revisions
gcloud run revisions list --service=ss --region=us-central1
```

### Access Service
```bash
# Get service URL
gcloud run services describe ss --region=us-central1 --format="value(status.url)"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**:
   - Ensure your account/service account has the required IAM roles
   - Check that the project ID is correct

2. **Build Failures**:
   - Verify `package.json` and `Dockerfile` are correctly configured
   - Check that all dependencies are listed in `package.json`

3. **Service Unreachable**:
   - Verify `--allow-unauthenticated` flag is set
   - Check that the PORT environment variable is being used correctly

4. **GitHub Actions Failures**:
   - Verify `GCP_CREDENTIALS` secret is valid JSON
   - Ensure repository variables are set correctly
   - Check service account permissions

### Useful Commands

```bash
# Delete service
gcloud run services delete ss --region=us-central1

# Update traffic allocation
gcloud run services update-traffic ss --to-latest --region=us-central1

# Scale service
gcloud run services update ss --max-instances=20 --region=us-central1
```

## Security Considerations

1. **Service Account Keys**: Rotate service account keys regularly
2. **Public Access**: The service allows unauthenticated access as required
3. **Resource Limits**: Configure appropriate CPU and memory limits
4. **Network**: Cloud Run services are HTTPS-only by default

## Cost Optimization

- **Auto-scaling**: Service scales down to zero when not in use
- **Resource Limits**: Configured with minimal required resources
- **Request-based Billing**: Only pay for actual usage
- **Regional Deployment**: Choose region closest to users for better performance and lower costs