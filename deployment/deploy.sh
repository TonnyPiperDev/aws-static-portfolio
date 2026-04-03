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
ACCOUNT_ID="YOUR_ACCOUNT_ID"           # AWS account ID
OAC_ID="YOUR_OAC_ID"                   # Origin Access Control ID
DISTRIBUTION_ID="YOUR_DISTRIBUTION_ID" # CloudFront distribution ID

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
  '{
    "Name": "YOUR_DOMAIN-oac",
    "Description": "OAC for YOUR_DOMAIN S3 bucket",
    "SigningProtocol": "sigv4",
    "SigningBehavior": "always",
    "OriginAccessControlOriginType": "s3"
  }'
# Save the OAC ID from the output

# ── Step 6: Create CloudFront distribution ────────────────────────────────
aws cloudfront create-distribution \
  --distribution-config \
  '{
    "CallerReference": "YOUR_DOMAIN-'$(date +%s)'",
    "Origins": {
      "Quantity": 1,
      "Items": [{
        "Id": "YOUR_DOMAIN-s3",
        "DomainName": "'"$BUCKET_NAME"'.s3.'"$REGION"'.amazonaws.com",
        "S3OriginConfig": {"OriginAccessIdentity": ""},
        "OriginAccessControlId": "'"$OAC_ID"'"
      }]
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "YOUR_DOMAIN-s3",
      "ViewerProtocolPolicy": "redirect-to-https",
      "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
      "AllowedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "DefaultRootObject": "coming-soon.html",
    "Aliases": {
      "Quantity": 2,
      "Items": ["'"$DOMAIN"'", "'"$WWW_DOMAIN"'"]
    },
    "ViewerCertificate": {
      "ACMCertificateArn": "'"$CERTIFICATE_ARN"'",
      "SSLSupportMethod": "sni-only",
      "MinimumProtocolVersion": "TLSv1.2_2021"
    },
    "Comment": "YOUR_DOMAIN portfolio",
    "Enabled": true,
    "HttpVersion": "http2"
  }'
# Save the Distribution ID and DomainName from the output
# Wait 5-15 minutes for Status to change from InProgress to Deployed

# ── Step 7: Apply bucket policy (CloudFront OAC only) ─────────────────────
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy \
  '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "AllowCloudFrontOAC",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'"$BUCKET_NAME"'/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::'"$ACCOUNT_ID"':distribution/'"$DISTRIBUTION_ID"'"
        }
      }
    }]
  }'

# ── Step 8: Upload website files to S3 ────────────────────────────────────
# Coming soon

echo "Deployment complete."
echo "Site: https://$DOMAIN"
