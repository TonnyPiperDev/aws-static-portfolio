# Portfolio Website — AWS Static Hosting

## What it does

This project hosts a static personal portfolio website on AWS with global CDN delivery, HTTPS enforcement, and a custom domain. The site is trilingual (EN/FR/DE), fully responsive, and includes a dark/light theme toggle. A coming soon version is served while the full portfolio is being finalised.

## Architecture

![Architecture Diagram](architecture-diagram.png)

## AWS Services Used

* S3
* CloudFront
* ACM (SSL/TLS certificate)
* IAM (bucket policy)

## Prerequisites

* AWS CLI installed and configured
* An AWS account with appropriate IAM permissions
* Domain registered with DNS managed via Cloudflare or Route 53

## Deployment

See the [deployment guide](deployment/deploy.sh) for step by step instructions, or run the automated script:
```
bash deployment/deploy.sh
```

## Author

Tonny Piper | [GitHub](https://github.com/TonnyPiperDev)
