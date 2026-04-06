# Cloud5ence — Vinod Kumar Dhanavath

> Personal portfolio and AWS DevOps practice project  
> Live at **[cloud5ence.com](https://cloud5ence.com)** · Built and deployed by Vinod Kumar Dhanavath

---

## What this repo contains

| File | Purpose |
|---|---|
| `cloud5ence.html` | The complete website (single-file SPA) |
| `WebsitePotrait.png` | Hero headshot photo |
| `Claud101_Cert.pdf` | Anthropic Claude 101 Certificate |
| `Vinod Kumar Dhanavath New - DevOps.pdf` | CV / Resume |
| `.github/workflows/deploy.yml` | GitHub Actions — auto-deploys on push to main |
| `infra/main.tf` | Terraform — S3 + CloudFront + ACM + Route 53 |
| `infra/variables.tf` | Terraform variables |

---

## Architecture

```
git push origin main
        │
        ▼
GitHub Actions (deploy.yml)
        │
        ├─ aws s3 sync → S3 Bucket (private, OAC only)
        └─ cloudfront create-invalidation
                               │
                        CloudFront (HTTPS)
                               │
                         Route 53 DNS
                               │
                        cloud5ence.com
```

**Cost: ~$0.55 CAD/month**

| Service | Cost |
|---|---|
| S3 (< 1 GB) | ~$0.03 |
| CloudFront (< 1 TB free tier) | $0.00 |
| Route 53 hosted zone | $0.50 |
| ACM certificate | $0.00 |

---

## How to update the website

Every update follows the same simple workflow:

```bash
# 1. Edit cloud5ence.html locally
# 2. Commit and push
git add cloud5ence.html
git commit -m "content: describe what you changed"
git push origin main
# 3. GitHub Actions deploys in ~60 seconds automatically
```

### Adding a new photo to the strip
```bash
cp your-photo.jpg photo7.jpg          # name it photo1.jpg through photo6.jpg
git add photo7.jpg
git commit -m "asset: add new photo to strip"
git push origin main
```

### Adding a new blog post
When ready to write articles, add them as separate HTML files or as sections inside `cloud5ence.html` and update the blog item links from `href="#"` to the article URL.

---

## Phase 1: Manual S3 Deploy (one-time setup)

```bash
# 1. Create S3 bucket
aws s3 mb s3://cloud5ence.com --region ca-central-1

# 2. Block public access (CloudFront uses OAC)
aws s3api put-public-access-block \
  --bucket cloud5ence.com \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 3. Upload website
aws s3 sync . s3://cloud5ence.com/ \
  --exclude ".git/*" --exclude ".github/*" \
  --exclude "infra/*" --exclude ".DS_Store"
```

## Phase 2: GitHub Actions (automated — after S3 + CF setup)

Add these 3 secrets in GitHub → Settings → Secrets → Actions:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `S3_BUCKET_NAME` | `cloud5ence.com` |
| `CLOUDFRONT_DISTRIBUTION_ID` | From Terraform output or AWS Console |

IAM policy for GitHub Actions (least privilege):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject","s3:DeleteObject","s3:ListBucket","s3:GetObject"],
      "Resource": ["arn:aws:s3:::cloud5ence.com","arn:aws:s3:::cloud5ence.com/*"]
    },
    {
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DIST_ID"
    }
  ]
}
```

## Phase 3: Terraform IaC

```bash
cd infra/
terraform init
terraform plan
terraform apply
```

---

## Roadmap

- [x] Website built and designed
- [x] GitHub repo structured
- [ ] S3 static hosting configured
- [ ] CloudFront + HTTPS live
- [ ] Route 53 DNS pointing to cloud5ence.com
- [ ] GitHub Actions auto-deploy working
- [ ] Terraform IaC for all infrastructure
- [ ] Contact form backend (API Gateway + Lambda + SES)
- [ ] Blog articles written and published
- [ ] CloudWatch monitoring dashboard

---

## Author

**Vinod Kumar Dhanavath**  
DevOps & Cloud Engineer · Ottawa, Canada  
AWS Certified DevOps Engineer Professional · Microsoft Certified DevOps Engineer Expert  
[cloud5ence.com](https://cloud5ence.com) · [LinkedIn](https://www.linkedin.com/in/vinod-kumar-dhanavath/) · [GitHub](https://github.com/VinodKumarDhanavath)
