# Manual Deployment to Google Cloud Run

This directory contains scripts for manually deploying the webrtc-screen-share application to Google Cloud Run.

## Overview

The application is deployed as a containerized service on Google Cloud Run with the following characteristics:
- **Service Name**: `ss` (neutral name to avoid detection)
- **Access**: Anonymous/unauthenticated access allowed
- **Platform**: Google Cloud Run (fully managed)
- **Container**: Node.js 18 with minimal dependencies

## Prerequisites

1. **Google Cloud CLI**: Install and configure the [gcloud CLI](https://cloud.google.com/sdk/docs/install)
2. **Authentication**: Run `gcloud auth login` to authenticate with your Google Cloud account
3. **Project Owner Role**: Your account needs project owner permissions for the deployment script to configure Cloud Build service account permissions
4. **Required APIs**: The deployment script will automatically enable required APIs

## Deployment

### Environment Setup

Before deploying, you must set the required environment variables:

```bash
# Set your Google Cloud project ID
export GOOGLE_CLOUD_PROJECT="your-project-id"

# Set your preferred region
export REGION="us-central1"
```

### Deploy to Cloud Run

Run the deployment script:

```bash
./cicd/gcp/deploy.sh
```

The deployment script will:
1. Validate that required environment variables are set
2. Set the gcloud project configuration
3. Configure Cloud Build service account permissions automatically
4. Enable required Google Cloud APIs
5. Build and deploy the application to Cloud Run
6. Output the service URL for testing

### Alternative Manual Deployment

If you prefer to deploy manually without the script:

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Deploy to Cloud Run
gcloud run deploy ss \
  --source . \
  --project=YOUR_PROJECT_ID \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --max-instances=10
```
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
- **Deployment script**: `cicd/gcp/deploy.sh`
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

4. **Environment Variables Not Set**:
   - Ensure `GOOGLE_CLOUD_PROJECT` and `REGION` environment variables are exported
   - Variables must be set in the same terminal session where you run the deploy script

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
