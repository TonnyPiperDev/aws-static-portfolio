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
CERTIFICATE_ARN="YOUR_CERTIFICATE_ARN" # ACM certificate ARN from us-east-1

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
aws acm request-certificate \
  --domain-name "$DOMAIN" \
  --subject-alternative-names "$WWW_DOMAIN" \
  --validation-method DNS \
  --region us-east-1
# After running: add the CNAME validation records to your DNS provider
# Then wait 5-30 minutes for status to change from PENDING_VALIDATION to ISSUED

# ── Step 5: Create CloudFront distribution ────────────────────────────────
# Coming soon

# ── Step 6: Apply bucket policy (CloudFront OAC only) ─────────────────────
# Coming soon

# ── Step 7: Upload website files to S3 ────────────────────────────────────
# Coming soon

echo "Deployment complete."
echo "Site: https://$DOMAIN"
