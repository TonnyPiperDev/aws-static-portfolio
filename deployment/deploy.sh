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
# Coming soon — populated during deployment walkthrough

# ── Step 2: Enable static website hosting ─────────────────────────────────
# Coming soon

# ── Step 3: Apply bucket policy ───────────────────────────────────────────
# Coming soon

# ── Step 4: Request ACM certificate (must be in us-east-1) ────────────────
# Coming soon

# ── Step 5: Create CloudFront distribution ────────────────────────────────
# Coming soon

# ── Step 6: Upload website files to S3 ────────────────────────────────────
# Coming soon

echo "Deployment complete."
echo "Site: https://$DOMAIN"
