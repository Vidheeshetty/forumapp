#!/bin/bash

# Forum App AWS Deployment Script

echo "🚀 Starting Forum App deployment..."

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "❌ zip is required but not installed."; exit 1; }

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Package Lambda function
echo "📦 Packaging Lambda function..."
cd ../lambda
npm install
zip -r forum-api.zip . -x "*.git*" "node_modules/.cache/*"
mv forum-api.zip ../terraform/
cd ../terraform

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan

# Apply deployment
echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve

# Get outputs
echo "📝 Getting deployment outputs..."
USER_POOL_ID=$(terraform output -raw user_pool_id)
USER_POOL_CLIENT_ID=$(terraform output -raw user_pool_client_id)
IDENTITY_POOL_ID=$(terraform output -raw identity_pool_id)
API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
AWS_REGION=$(terraform output -raw aws_region)

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📱 Update your Flutter app with these values:"
echo "=================================="
echo "USER_POOL_ID: $USER_POOL_ID"
echo "USER_POOL_CLIENT_ID: $USER_POOL_CLIENT_ID"
echo "IDENTITY_POOL_ID: $IDENTITY_POOL_ID"
echo "API_GATEWAY_ENDPOINT: $API_GATEWAY_URL"
echo "S3_BUCKET_NAME: $S3_BUCKET_NAME"
echo "AWS_REGION: $AWS_REGION"
echo "=================================="
echo ""
echo "📋 Copy these values to lib/amplifyconfiguration.dart"
echo ""

# Create a config file for easy reference
cat > ../flutter_config.txt << EOF
Replace in lib/amplifyconfiguration.dart:

YOUR_USER_POOL_ID -> $USER_POOL_ID
YOUR_APP_CLIENT_ID -> $USER_POOL_CLIENT_ID
YOUR_IDENTITY_POOL_ID -> $IDENTITY_POOL_ID
YOUR_API_GATEWAY_ENDPOINT -> $API_GATEWAY_URL
YOUR_S3_BUCKET_NAME -> $S3_BUCKET_NAME

Region: $AWS_REGION
EOF

echo "💾 Configuration saved to ../flutter_config.txt"