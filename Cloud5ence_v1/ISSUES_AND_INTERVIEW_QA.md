# Cloud5ence Project — Real Issues & Interview Q&A

**Project:** AWS Static Website — cloud5ence.com  
**Use this to:** Revise before interviews, answer architecture questions, explain decisions

---

## REAL ISSUES FACED & HOW THEY WERE RESOLVED

---

### Issue 1 — Terraform Provider Alias with Hyphens

**Error:**
```
Error: Provider configuration not present
provider["registry.terraform.io/hashicorp/aws"].us-east-1 is required
but it has been removed
```

**Root Cause:**  
Terraform provider aliases cannot contain hyphens. The alias was named `"us-east-1"` which Terraform treats inconsistently across versions. A leftover state file from a previous run also conflicted.

**Fix:**
```hcl
# Wrong
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Correct
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

Also cleared stale state:
```bash
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
terraform init
```

**Why ACM needs a separate provider:**  
CloudFront only accepts ACM certificates provisioned in `us-east-1` — regardless of which region your other resources are in. This is an AWS hard requirement, not optional.

---

### Issue 2 — IAM Permissions Too Narrow (Whack-a-mole)

**Error sequence:**
```
AccessDenied: s3:CreateBucket
AccessDenied: acm:RequestCertificate
AccessDenied: cloudfront:CreateOriginAccessControl
AccessDenied: route53:CreateHostedZone
AccessDenied: s3:GetBucketAcl
AccessDenied: s3:GetBucketCORS
```

**Root Cause:**  
The IAM user was created with only deployment permissions (S3 sync + CloudFront invalidation). Terraform needs **infrastructure creation** permissions which are much broader.

**Fix:**  
Separated concerns into two permission sets:
- **Terraform execution:** Full S3 (`s3:*` on specific bucket), CloudFront create/manage, ACM, Route 53
- **GitHub Actions deployment:** S3 sync only + CloudFront invalidation only

**Lesson:**  
Always design IAM policies for the specific use case. Terraform needs `Create/Delete/Describe` permissions. CI/CD pipelines only need `PutObject/DeleteObject/Sync` and `CreateInvalidation`. Never give CI/CD pipeline Terraform-level permissions.

---

### Issue 3 — ACM Certificate Stuck in PENDING_VALIDATION

**Symptom:**
```
aws_acm_certificate_validation.site: Still creating... [10m elapsed]
aws_acm_certificate_validation.site: Still creating... [20m elapsed]
```

**Root Cause:**  
ACM validates ownership by checking for specific CNAME records in your DNS. The DNS validation records were created in Route 53, but `cloud5ence.com` was still pointing to GoDaddy's nameservers — so ACM could never find the validation records.

**Fix:**  
Updated GoDaddy nameservers to Route 53 while Terraform was still running. Once DNS propagated, ACM found the validation CNAME records and automatically issued the certificate. Terraform then continued creating CloudFront.

**Key Terraform addition:**
```hcl
resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront depends_on validation — not just the certificate resource
resource "aws_cloudfront_distribution" "site" {
  depends_on = [aws_acm_certificate_validation.site]
  ...
}
```

Without `depends_on`, Terraform tried to use the certificate before it was issued — causing `InvalidViewerCertificate` error.

---

### Issue 4 — CloudFront InvalidViewerCertificate

**Error:**
```
InvalidViewerCertificate: The specified SSL certificate doesn't exist,
isn't in us-east-1 region, isn't valid, or doesn't include a valid
certificate chain.
```

**Root Cause:**  
CloudFront was created before the ACM certificate finished validation. A `PENDING_VALIDATION` certificate cannot be attached to a CloudFront distribution.

**Fix:**  
Added `aws_acm_certificate_validation` resource and `depends_on` to enforce correct creation order. CloudFront now waits for the certificate to reach `ISSUED` status before being created.

---

### Issue 5 — S3 Access Denied on Website

**Symptom:**
```xml
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
</Error>
```

**Root Cause (multiple):**
1. Files were uploaded to `s3://cloud5ence.com/Cloud5ence_v1/` subfolder instead of bucket root
2. CloudFront was looking for `cloud5ence.html` at root level

**Fix:**
```bash
# Sync from the correct local subfolder to bucket root
aws s3 sync Cloud5ence_v1/ s3://cloud5ence.com/ \
  --exclude ".git/*" --exclude ".github/*" --exclude "infra/*"
```

Also fixed GitHub Actions deploy.yml:
```yaml
# Wrong — syncs from repo root (creates subfolder in S3)
aws s3 sync . s3://${{ secrets.S3_BUCKET_NAME }}/

# Correct — syncs from website subfolder to bucket root
aws s3 sync ./Cloud5ence_v1/ s3://${{ secrets.S3_BUCKET_NAME }}/
```

---

### Issue 6 — GitHub Actions Workflow Not Found

**Symptom:**  
GitHub Actions tab showed "Get started with GitHub Actions" instead of running the workflow.

**Root Cause:**  
The `deploy.yml` file was inside `Cloud5ence_v1/.github/workflows/` (a subfolder) instead of the repo root `.github/workflows/`. GitHub Actions only looks for workflows at the repository root.

**Fix:**
```bash
mkdir -p .github/workflows
cp Cloud5ence_v1/.github/workflows/deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "ci: fix deploy workflow location"
git push origin main
```

---

### Issue 7 — GoDaddy Nameservers Not Updated

**Symptom:**  
`dig NS cloud5ence.com +short` kept returning GoDaddy nameservers even after supposedly updating them. Website showed GoDaddy default page.

**Root Cause:**  
The nameserver change in GoDaddy was navigated to via the DNS Records tab. The actual nameserver settings are on a separate **Nameservers** tab. The change was never actually saved.

**Fix:**  
GoDaddy → Domain → DNS → **Nameservers tab** (not DNS Records tab) → Change → Enter my own nameservers → paste all 4 Route 53 nameservers → Save.

**Verification:**
```bash
dig NS cloud5ence.com +short
# Should return Route 53 nameservers, not ns15/ns16.domaincontrol.com
```

---

## INTERVIEW Q&A

---

### Q1: Why did you use S3 + CloudFront instead of EC2 to host a static website?

**Answer:**  
A static website has no server-side processing — it's just HTML, CSS, JS, and images. Running an EC2 instance for this would mean paying for compute 24/7, managing OS patches, handling availability zones, and scaling manually. S3 + CloudFront gives you 11 nines of durability, global CDN with 400+ edge locations, automatic HTTPS via ACM, and it costs under $1/month. EC2 would cost $15–30/month minimum. For static content, S3 + CloudFront is always the right answer.

---

### Q2: What is CloudFront OAC and why did you use it instead of OAI?

**Answer:**  
OAC (Origin Access Control) is the modern replacement for OAI (Origin Access Identity). Both restrict S3 bucket access to only CloudFront — the bucket stays private and users can't bypass CloudFront to access S3 directly. OAC is preferred because it supports additional S3 features like SSE-KMS encryption, supports all S3 regions, and uses SigV4 signing for requests. OAI is legacy and AWS recommends migrating to OAC. In the S3 bucket policy, OAC is referenced via `AWS:SourceArn` condition pointing to the specific CloudFront distribution ARN — much more secure than OAI which used a shared identity.

---

### Q3: Why must the ACM certificate be in us-east-1?

**Answer:**  
CloudFront is a global service that runs at AWS edge locations worldwide. When CloudFront needs to serve HTTPS traffic, it looks for the SSL certificate in a single specific location — `us-east-1` (N. Virginia). This is an AWS architectural decision — CloudFront's control plane is in us-east-1. If you provision the certificate in any other region, CloudFront simply cannot find it. This is why in Terraform we define a separate AWS provider with `alias = "us_east_1"` and explicitly reference it in the `aws_acm_certificate` resource.

---

### Q4: Explain the Terraform `depends_on` you used and why it was necessary.

**Answer:**  
`depends_on = [aws_acm_certificate_validation.site]` on the CloudFront distribution tells Terraform to wait until the ACM certificate is fully validated (status = `ISSUED`) before creating CloudFront. Without this, Terraform creates resources in parallel wherever possible. It would start creating CloudFront at the same time as the certificate, and since the certificate is still `PENDING_VALIDATION`, CloudFront rejects it with `InvalidViewerCertificate`. The `aws_acm_certificate_validation` resource is a special Terraform resource that actively polls ACM until the certificate is issued — it's not just a dependency marker, it actually blocks until validation completes.

---

### Q5: What is the principle of least privilege and how did you apply it?

**Answer:**  
Least privilege means giving an identity only the permissions it needs to do its job — nothing more. I applied it in two ways. First, the Terraform execution user was given specific permissions for S3, CloudFront, ACM, and Route 53 — scoped to only the `cloud5ence.com` bucket where possible. Second, the GitHub Actions CI/CD pipeline uses a separate credential that only has `s3:*` on the specific bucket and `cloudfront:CreateInvalidation` — it cannot create or delete infrastructure. This means even if the GitHub Actions secrets were compromised, an attacker could only overwrite website files, not destroy the AWS infrastructure.

---

### Q6: How does your CI/CD pipeline work end to end?

**Answer:**  
When I run `git push origin main`, GitHub Actions triggers the deploy workflow automatically. The workflow runs on an Ubuntu runner and has five steps: checkout the repo, configure AWS credentials using the stored secrets, sync HTML files to S3 with `no-cache` headers so updates are instant, sync asset files (images, PDFs) with 1-year cache headers since they rarely change, then create a CloudFront invalidation to clear cached content at all edge locations globally. The entire pipeline takes about 12 seconds. The cache strategy is important — if I used long-cache on HTML, users would see the old version for hours even after deployment.

---

### Q7: What is DNS propagation and why did it take time?

**Answer:**  
DNS propagation is the process of updating DNS records across all recursive resolvers worldwide. When I changed cloud5ence.com's nameservers from GoDaddy to Route 53, every DNS resolver on the internet needed to learn about this change. DNS resolvers cache records based on their TTL (Time To Live). GoDaddy's default TTL for nameserver records is typically 3600 seconds (1 hour) to 48 hours. Until the TTL expires, resolvers keep serving the old GoDaddy nameservers. Propagation doesn't happen at once — it spreads gradually from resolver to resolver. I used `dig NS cloud5ence.com +short` to check and `dnschecker.org` to see global propagation status.

---

### Q8: Why use Terraform instead of clicking through the AWS Console?

**Answer:**  
Three main reasons. First, repeatability — if I need to rebuild this infrastructure in a new account or region, I run `terraform apply` and it's done in 10 minutes instead of hours of clicking. Second, version control — all infrastructure changes go through git, so I have a full audit trail of what changed, when, and why. Third, documentation — the Terraform code is self-documenting infrastructure. Anyone can read `main.tf` and understand exactly what AWS resources exist and how they're connected. In a team environment, this also enables code review for infrastructure changes — the same discipline applied to application code.

---

### Q9: What would you add to make this more production-hardened?

**Answer:**  
Several things. First, AWS WAF in front of CloudFront for rate limiting and bot protection. Second, CloudWatch alarms for 4xx/5xx error rates and cache hit ratio. Third, S3 access logging to track requests. Fourth, a contact form backend using API Gateway + Lambda + SES so the contact form actually sends emails. Fifth, moving Terraform state to S3 backend with DynamoDB locking so state is shared and locked in team environments. Sixth, using OIDC instead of long-lived IAM access keys for GitHub Actions — this eliminates stored credentials entirely and is the current AWS best practice.

---

### Q10: What is the difference between Route 53 Alias records and CNAME records?

**Answer:**  
Both map a domain name to another domain name, but they behave differently. A CNAME cannot be used at the zone apex (root domain like `cloud5ence.com`) — only on subdomains. An Alias record is an AWS Route 53 extension that can be used at the zone apex. Alias records also have a performance advantage — Route 53 resolves the alias target and returns the IP directly, avoiding an extra DNS lookup. Most importantly, Alias records to AWS resources like CloudFront are free — Route 53 doesn't charge for alias queries to CloudFront, ALB, S3 etc. CNAME queries would be billed at $0.40/million. For this project I used Alias A records for both `cloud5ence.com` and `www.cloud5ence.com` pointing to CloudFront.
