#!/bin/bash
# =============================================================================
# deploy.sh — Static Portfolio Website Deployment
# =============================================================================
# Usage: bash deployment/deploy.sh
# Prerequisites: AWS CLI installed and configured, appropriate IAM permissions
# =============================================================================
# BEFORE RUNNING:
# Replace all placeholder values below with your own configuration.
# =============================================================================

set -e  # Exit immediately on error

# ── Configuration — replace with your own values ──────────────────────────
BUCKET_NAME="YOUR_DOMAIN"            # e.g. tonnypiper.dev
REGION="YOUR_REGION"                 # e.g. eu-central-1
WEBSITE_DIR="./website"              # path to your website files
DOMAIN="YOUR_DOMAIN"                 # e.g. tonnypiper.dev
WWW_DOMAIN="www.YOUR_DOMAIN"         # e.g. www.tonnypiper.dev

# ── Step 1: Create S3 bucket ───────────────────────────────────────────────
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# ── Step 2: Enable static website hosting ─────────────────────────────────
aws s3 website s3://"$BUCKET_NAME" \
  --index-document index.html \
  --error-document error.html

# ── Step 3: Verify public access block is on (S3 stays private) ───────────
aws s3api get-public-access-block --bucket "$BUCKET_NAME"

# ── Step 4: Request ACM certificate (must be in us-east-1) ────────────────
# Coming soon

# ── Step 5: Create CloudFront distribution ────────────────────────────────
# Coming soon

# ── Step 6: Apply bucket policy (CloudFront OAC only) ─────────────────────
# Coming soon

# ── Step 7: Upload website files to S3 ────────────────────────────────────
# Coming soon

echo "Deployment complete."
echo "Site: https://$DOMAIN"
