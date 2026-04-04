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
BUCKET_NAME="YOUR_DOMAIN"              # e.g. tonnypiper.dev
REGION="YOUR_REGION"                   # e.g. eu-central-1
WEBSITE_DIR="./website"                # path to your website files
DOMAIN="YOUR_DOMAIN"                   # e.g. tonnypiper.dev
WWW_DOMAIN="www.YOUR_DOMAIN"           # e.g. www.tonnypiper.dev
CERTIFICATE_ARN="YOUR_CERTIFICATE_ARN" # ACM certificate ARN from us-east-1
DISTRIBUTION_ID="YOUR_DISTRIBUTION_ID" # CloudFront distribution ID
OAC_ID="YOUR_OAC_ID"                   # Origin Access Control ID
ACCOUNT_ID="YOUR_ACCOUNT_ID"           # AWS account ID
ALERT_EMAIL="YOUR_AWS_EMAIL"           # e.g. aws@yourdomain.dev

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

# ── Step 5: Create Origin Access Control ──────────────────────────────────
aws cloudfront create-origin-access-control \
  --origin-access-control-config \
  "{\"Name\": \"${BUCKET_NAME}-oac\",
    \"Description\": \"OAC for ${BUCKET_NAME} S3 bucket\",
    \"SigningProtocol\": \"sigv4\",
    \"SigningBehavior\": \"always\",
    \"OriginAccessControlOriginType\": \"s3\"}"

# ── Step 6: Create CloudFront distribution ────────────────────────────────
# See distribution.json for full config
# Key fields: OAC ID, ACM cert ARN, domain aliases, redirect-to-https
# After running: add CNAME in DNS provider pointing to CloudFront domain
# Wait 5-15 minutes for Status: InProgress → Deployed

# ── Step 7: Apply bucket policy (CloudFront OAC only) ─────────────────────
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy \
  "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"AllowCloudFrontOAC\",
      \"Effect\": \"Allow\",
      \"Principal\": {\"Service\": \"cloudfront.amazonaws.com\"},
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\",
      \"Condition\": {
        \"StringEquals\": {
          \"AWS:SourceArn\": \"arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}\"
        }
      }
    }]
  }"

# ── Step 8: Configure custom error responses ──────────────────────────────
# Serves error.html for 403 and 404 errors instead of raw S3 XML
# Run after distribution is deployed — requires current ETag
# aws cloudfront update-distribution --id "$DISTRIBUTION_ID" --if-match YOUR_ETAG ...

# ── Step 9: Upload website files to S3 ────────────────────────────────────
aws s3 sync "$WEBSITE_DIR" s3://"$BUCKET_NAME" \
  --region "$REGION"

# ── Step 10: Invalidate CloudFront cache ──────────────────────────────────
# Run this every time you update website files
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*"

# ── Step 11: Billing protection (us-east-1 only) ──────────────────────────
aws sns create-topic --name billing-alert --region us-east-1

aws sns subscribe \
  --topic-arn "arn:aws:sns:us-east-1:${ACCOUNT_ID}:billing-alert" \
  --protocol email \
  --notification-endpoint "$ALERT_EMAIL" \
  --region us-east-1
# Confirm subscription in your email inbox before proceeding

aws cloudwatch put-metric-alarm \
  --alarm-name "monthly-billing-alert" \
  --alarm-description "Alert when AWS charges exceed 10 USD" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:us-east-1:${ACCOUNT_ID}:billing-alert" \
  --dimensions Name=Currency,Value=USD \
  --region us-east-1

echo "Deployment complete."
echo "Site: https://$DOMAIN"
