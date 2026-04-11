# Cloud5ence.com — AWS Static Website Hosting Project

**Project:** Personal Portfolio Website — End-to-End AWS Deployment  
**Owner:** Vinod Kumar Dhanavath  
**Live URL:** https://cloud5ence.com  
**GitHub:** https://github.com/VinodKumarDhanavath/Cloud5ence  
**Duration:** April 2026  
**Status:** ✅ Live in Production

---

## Project Overview

Designed, built, and deployed a production-grade personal portfolio website using a full DevOps pipeline on AWS. The project covers everything from static website development to infrastructure provisioning using Terraform IaC, automated CI/CD using GitHub Actions, and global content delivery via CloudFront CDN.

This project deliberately mirrors real enterprise deployment patterns used in regulated industries — the same stack used for much larger workloads at National Bank and Intact Insurance, applied to a personal website to demonstrate end-to-end ownership.

---

## Architecture

```
Developer (VS Code + Live Server)
            │
            │  git push origin main
            ▼
    GitHub Repository
    (VinodKumarDhanavath/Cloud5ence)
            │
            │  GitHub Actions trigger (on: push)
            ▼
    GitHub Actions CI/CD Runner
    ├── aws s3 sync → S3 Bucket
    └── cloudfront create-invalidation
            │
            ▼
    Amazon S3 (cloud5ence.com)
    Private bucket — OAC access only
            │
            ▼
    Amazon CloudFront (E1NPERCOAFADC3)
    Global CDN — 400+ edge locations
    HTTPS enforced — TLSv1.2_2021
            │
            ▼
    AWS ACM Certificate
    DNS validated — auto-renews
            │
            ▼
    Amazon Route 53 (Z02544303RYYNJS5WERA6)
    Hosted zone — Alias A records
            │
            ▼
    GoDaddy Domain (cloud5ence.com)
    Nameservers → Route 53
            │
            ▼
    https://cloud5ence.com ✅
```

---

## Technology Stack

| Layer | Service / Tool | Purpose |
|---|---|---|
| Website | HTML5, CSS3, Vanilla JS | Single-file SPA — no framework |
| Source control | GitHub | Version control + CI/CD trigger |
| CI/CD | GitHub Actions | Auto-deploy on every git push |
| Storage | Amazon S3 | Static file hosting (private) |
| CDN | Amazon CloudFront | Global delivery + HTTPS |
| SSL/TLS | AWS ACM | Free auto-renewing certificate |
| DNS | Amazon Route 53 | Hosted zone + Alias A records |
| Domain | GoDaddy | Domain registrar |
| IaC | Terraform >= 1.5 | All AWS infrastructure as code |
| Access control | AWS IAM | Least-privilege deployer user |
| Security | CloudFront OAC | S3 bucket never public |

---

## AWS Resources Created

| Resource | ID / Name |
|---|---|
| S3 Bucket | cloud5ence.com |
| CloudFront Distribution | E1NPERCOAFADC3 |
| CloudFront Domain | dwg3f38wotsg4.cloudfront.net |
| ACM Certificate | arn:aws:acm:us-east-1:371170754116:certificate/29434636... |
| Route 53 Hosted Zone | Z02544303RYYNJS5WERA6 |
| IAM User | cloud5ence-deployer |
| IAM Policy | cloud5ence-deployer-policy |
| AWS Region | us-east-1 |

---

## Infrastructure as Code (Terraform)

All AWS infrastructure is defined in `infra/main.tf` and provisioned with a single `terraform apply`. Resources created:

- `aws_s3_bucket` — private bucket, versioning enabled
- `aws_s3_bucket_public_access_block` — all public access blocked
- `aws_s3_bucket_versioning` — enabled for rollback capability
- `aws_acm_certificate` — DNS validated, us-east-1 (required for CloudFront)
- `aws_route53_record.cert_validation` — automatic DNS validation records
- `aws_acm_certificate_validation` — waits for certificate ISSUED status
- `aws_cloudfront_origin_access_control` — OAC for secure S3 access
- `aws_cloudfront_distribution` — global CDN, HTTPS redirect, custom error
- `aws_s3_bucket_policy` — allows only CloudFront OAC, denies everything else
- `aws_route53_zone` — hosted zone for cloud5ence.com
- `aws_route53_record.root` — A record (Alias → CloudFront)
- `aws_route53_record.www` — A record (Alias → CloudFront)

---

## CI/CD Pipeline

**Trigger:** Every `git push` to `main` branch

**Steps:**
1. Checkout repository
2. Configure AWS credentials (from GitHub Secrets)
3. `aws s3 sync` — HTML files with `no-cache` headers
4. `aws s3 sync` — Assets (images, PDFs) with 1-year cache headers
5. `aws cloudfront create-invalidation` — clears CDN cache globally

**Average deployment time:** ~12 seconds

**GitHub Secrets required:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET_NAME`
- `CLOUDFRONT_DISTRIBUTION_ID`

---

## Security Design

- S3 bucket is **completely private** — no public access
- CloudFront accesses S3 via **Origin Access Control (OAC)** — modern replacement for OAI
- S3 bucket policy restricts access to **only this CloudFront distribution** using `AWS:SourceArn` condition
- IAM user follows **least privilege** — only S3 sync + CloudFront invalidation permissions
- HTTPS enforced — **redirect-to-https** policy on CloudFront
- TLS minimum version: **TLSv1.2_2021**
- ACM certificate covers both `cloud5ence.com` and `www.cloud5ence.com`

---

## Cost

| Service | Monthly | Annual |
|---|---|---|
| Amazon S3 | ~$0.01 | ~$0.12 |
| Amazon CloudFront | $0.00 (free tier) | $0.00 |
| AWS ACM | $0.00 (always free) | $0.00 |
| Amazon Route 53 | $0.50 | $6.00 |
| IAM | $0.00 (always free) | $0.00 |
| GitHub Actions | $0.00 (public repo) | $0.00 |
| **Total AWS** | **~$0.51** | **~$6.12 CAD** |

---

## Key Learnings

1. ACM certificates for CloudFront **must** be provisioned in `us-east-1` regardless of your primary region
2. Terraform provider aliases cannot contain hyphens — use `us_east_1` not `us-east-1`
3. Certificate validation requires DNS propagation — `depends_on` in Terraform ensures correct ordering
4. CloudFront OAC requires `AWS:SourceArn` condition in S3 bucket policy (not just `Principal`)
5. S3 sync path must match repo structure — files must be at bucket root, not in subfolders
6. GoDaddy nameserver changes can take up to 2 hours to propagate globally
7. Cache headers matter — HTML should be `no-cache` for instant updates, assets can have 1-year cache

---

## Repository Structure

```
Cloud5ence/
├── Cloud5ence_v1/
│   ├── cloud5ence.html              # Complete website (SPA)
│   ├── WebsitePotrait.png           # Hero headshot
│   ├── Ottawa.jpg                   # Photo strip
│   ├── Workspace.jpg
│   ├── working.jpg
│   ├── Personal.jpg
│   ├── Team.png
│   ├── Claud101_Cert.pdf            # Claude 101 certificate
│   ├── Vinod Kumar Dhanavath New - DevOps.pdf  # Resume
│   ├── .github/workflows/
│   │   └── deploy.yml               # GitHub Actions CI/CD
│   ├── infra/
│   │   ├── main.tf                  # All AWS infrastructure
│   │   └── variables.tf
│   ├── .gitignore
│   ├── README.md
│   └── CUSTOMISE.md                 # Update guide
```
