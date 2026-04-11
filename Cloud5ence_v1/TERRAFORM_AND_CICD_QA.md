# Terraform & GitHub Actions — Interview Q&A

**Project context:** cloud5ence.com — AWS static website deployment  
**Use this to:** Revise before DevOps interviews, explain IaC and CI/CD decisions

---

## SECTION 1 — TERRAFORM FUNDAMENTALS

---

### Q1: What is Terraform and why did you use it instead of AWS CloudFormation?

**Answer:**  
Terraform is an open-source Infrastructure as Code tool by HashiCorp that lets you define, provision, and manage cloud infrastructure using declarative configuration files. I used it instead of CloudFormation for three reasons. First, Terraform is cloud-agnostic — the same tool and workflow works across AWS, Azure, and GCP. Since I work across all three clouds professionally, using Terraform means I only need to learn one IaC tool. Second, Terraform has a cleaner, more readable syntax (HCL) compared to CloudFormation's verbose JSON/YAML. Third, Terraform's plan/apply workflow gives you a preview of exactly what will change before anything happens — CloudFormation's change sets are more complex to work with.

---

### Q2: Explain the Terraform workflow — init, plan, apply, destroy.

**Answer:**  
- `terraform init` — Downloads required provider plugins (in our case the AWS provider) and initialises the working directory. Must be run first or after any provider version change.
- `terraform plan` — Compares your configuration files against the current state and shows exactly what will be created, modified, or destroyed. Nothing changes in AWS at this stage. Always review the plan before applying.
- `terraform apply` — Executes the plan and makes the actual API calls to AWS to create/modify/destroy resources. Prompts for confirmation unless you pass `-auto-approve`.
- `terraform destroy` — Destroys all resources managed by the current state file. Used for teardown only — never run this on production infrastructure unless you intend to permanently delete everything.

---

### Q3: What is a Terraform state file and why is it important?

**Answer:**  
The `terraform.tfstate` file is Terraform's record of what infrastructure it has created and manages. It maps your configuration resources to real-world AWS resource IDs. For example it knows that `aws_s3_bucket.site` corresponds to the actual S3 bucket named `cloud5ence.com` with ARN `arn:aws:s3:::cloud5ence.com`.

It's important for three reasons:
1. **Change detection** — Terraform compares your config against state to calculate what needs to change
2. **Dependency tracking** — State tracks relationships between resources
3. **Idempotency** — Running `terraform apply` twice won't create duplicate resources because state shows they already exist

**Critical:** State files can contain sensitive data (resource IDs, ARNs, sometimes credentials). Never commit them to version control. In production, store state in an S3 backend with DynamoDB locking.

---

### Q4: What is a Terraform backend and why should you use S3 backend in production?

**Answer:**  
By default Terraform stores state locally on your machine. A backend tells Terraform to store state remotely instead. For production I would use the S3 backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "cloud5ence-tfstate"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud5ence-tfstate-lock"
    encrypt        = true
  }
}
```

**Three reasons for S3 backend:**
1. **Shared state** — Team members all work from the same state file
2. **State locking** — DynamoDB table prevents two engineers running `terraform apply` simultaneously, which would corrupt state
3. **Security** — State is encrypted at rest in S3, not sitting on a local laptop

For cloud5ence.com I used local state since it's a solo project, but I documented the S3 backend config as a comment in `main.tf` for reference.

---

### Q5: What is the difference between `terraform.tfstate` and `terraform.tfstate.backup`?

**Answer:**  
Every time `terraform apply` runs successfully, Terraform saves the previous state as `terraform.tfstate.backup` before overwriting `terraform.tfstate` with the new state. It's an automatic single-version rollback. If something goes wrong during apply and your state gets corrupted, you can restore from the backup. However this is not a substitute for proper remote state management — with S3 backend you get full state history through S3 versioning, which is far more reliable.

---

### Q6: What are Terraform providers and why did you need two AWS providers?

**Answer:**  
A provider is a plugin that lets Terraform interact with a specific API — in our case the AWS provider makes API calls to AWS services. I needed two AWS providers because ACM certificates for CloudFront must be provisioned in `us-east-1` regardless of your primary region. CloudFront's control plane is global but reads certificates only from `us-east-1`.

```hcl
# Primary provider — all resources except ACM
provider "aws" {
  region = var.aws_region  # us-east-1 in our case
}

# Secondary provider — ACM certificate only
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ACM explicitly uses the aliased provider
resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1
  ...
}
```

**Important:** Provider aliases cannot contain hyphens. `alias = "us-east-1"` fails — must be `alias = "us_east_1"`.

---

### Q7: What is `depends_on` in Terraform and when should you use it?

**Answer:**  
`depends_on` explicitly tells Terraform that one resource must be fully created before another starts. Terraform normally handles dependencies automatically by analysing resource references — if resource B references resource A's output, Terraform knows to create A first. But sometimes the dependency isn't expressed through a reference and Terraform can't detect it automatically.

In our project:
```hcl
resource "aws_cloudfront_distribution" "site" {
  depends_on = [aws_acm_certificate_validation.site]
  ...
}
```

CloudFront references the certificate ARN (which Terraform detects), but it doesn't know it needs to wait for the certificate to be fully **validated** — not just created. Without `depends_on`, Terraform creates CloudFront using a `PENDING_VALIDATION` certificate, which AWS rejects with `InvalidViewerCertificate`. The `depends_on` forces Terraform to wait until the certificate reaches `ISSUED` status.

---

### Q8: What is `for_each` in Terraform and how did you use it?

**Answer:**  
`for_each` creates multiple instances of a resource from a map or set. I used it to create ACM DNS validation records:

```hcl
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = aws_route53_zone.site.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}
```

ACM requires one CNAME validation record per domain name — `cloud5ence.com` and `www.cloud5ence.com`. Rather than writing two separate `aws_route53_record` blocks, `for_each` iterates over the certificate's `domain_validation_options` and creates one record per domain automatically.

---

### Q9: What are Terraform output values and why did you use them?

**Answer:**  
Output values expose specific attributes of your infrastructure after `terraform apply` completes. They're useful for capturing values you need elsewhere — in our case, values needed to configure GitHub Secrets and GoDaddy nameservers:

```hcl
output "nameservers" {
  value       = aws_route53_zone.site.name_servers
  description = "Paste these 4 into GoDaddy nameservers"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.site.id
  description = "Add to GitHub secret: CLOUDFRONT_DISTRIBUTION_ID"
}
```

After `terraform apply`, these values printed automatically — I copied the CloudFront ID into GitHub Secrets and the nameservers into GoDaddy. Without outputs I'd have to go digging through the AWS Console to find these values manually.

---

### Q10: What are Terraform variables and how did you use them?

**Answer:**  
Variables make Terraform configurations reusable and environment-agnostic. Instead of hardcoding values, you define variables and reference them:

```hcl
# variables.tf
variable "domain_name" {
  type    = string
  default = "cloud5ence.com"
}

# main.tf — reference with var.
resource "aws_s3_bucket" "site" {
  bucket = var.domain_name
}
```

This means if I wanted to deploy an identical setup for a different domain, I only change `variables.tf` — not every resource in `main.tf`. In production you'd use `terraform.tfvars` files for different environments (dev, staging, prod) — each with their own variable values.

---

## SECTION 2 — GITHUB ACTIONS

---

### Q11: What is GitHub Actions and how does it work?

**Answer:**  
GitHub Actions is a CI/CD platform built into GitHub. It runs automated workflows triggered by events in your repository — in our case, every `git push` to the `main` branch. Workflows are defined as YAML files in `.github/workflows/`. When a trigger event occurs, GitHub spins up a fresh virtual machine (runner), checks out your code, and executes the steps you defined. For cloud5ence.com, the workflow authenticates to AWS and syncs files to S3 — the entire deployment takes 12 seconds.

---

### Q12: Explain the structure of a GitHub Actions workflow file.

**Answer:**  
```yaml
name: Deploy cloud5ence.com to AWS   # Workflow name shown in UI

on:                                   # Trigger events
  push:
    branches: [main]                  # Runs on every push to main
  workflow_dispatch:                  # Also allows manual trigger from UI

jobs:                                 # One or more jobs (run in parallel by default)
  deploy:
    name: Sync to S3 + Invalidate CloudFront
    runs-on: ubuntu-latest            # Runner OS

    steps:                            # Sequential steps within the job
      - name: Checkout                # Step name
        uses: actions/checkout@v4    # Reusable action from marketplace

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:                         # Input parameters for the action
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}

      - name: Sync files
        run: aws s3 sync ...          # Shell command
```

---

### Q13: What are GitHub Secrets and why are they important?

**Answer:**  
GitHub Secrets are encrypted environment variables stored in your repository settings. They're used to pass sensitive values to workflows without hardcoding them in the YAML file. In our workflow we use four secrets:

- `AWS_ACCESS_KEY_ID` — IAM user access key
- `AWS_SECRET_ACCESS_KEY` — IAM user secret key
- `S3_BUCKET_NAME` — S3 bucket name
- `CLOUDFRONT_DISTRIBUTION_ID` — CloudFront distribution ID

They're referenced in workflows as `${{ secrets.SECRET_NAME }}`. GitHub masks secret values in logs — you'll never see the actual value printed. If secrets were hardcoded in the YAML file and committed to a public repo, anyone could see your AWS credentials and take over your account. Never hardcode credentials in code.

---

### Q14: What is the difference between `uses` and `run` in GitHub Actions?

**Answer:**  
- `uses` — References a pre-built reusable action from the GitHub Marketplace or another repo. Actions are packaged workflows written by others. For example `actions/checkout@v4` handles all the git clone logic, and `aws-actions/configure-aws-credentials@v4` handles AWS authentication including assuming roles, setting environment variables, and cleaning up after the job.
- `run` — Executes a raw shell command directly on the runner. Used for custom commands like `aws s3 sync` or `aws cloudfront create-invalidation`.

Use `uses` when a well-maintained action exists for the task — it's more reliable and handles edge cases. Use `run` for simple shell commands or when no suitable action exists.

---

### Q15: What is `workflow_dispatch` and why is it useful?

**Answer:**  
`workflow_dispatch` is a trigger that allows you to manually run a workflow from the GitHub Actions UI without pushing a commit. It's useful for:
1. **Re-running a failed deployment** without making a dummy commit
2. **Deploying to production manually** after reviewing changes
3. **Testing the workflow** itself without polluting git history
4. **Emergency deployments** — if you need to push a hotfix quickly

In our workflow I include it alongside the `push` trigger so I can manually re-deploy at any time from the GitHub UI with one click.

---

### Q16: How would you improve this CI/CD pipeline for a larger production system?

**Answer:**  
Several improvements for production scale:

1. **OIDC instead of IAM access keys** — Use OpenID Connect to have GitHub Actions assume an IAM role directly, eliminating long-lived credentials stored as secrets entirely
2. **Environment protection rules** — Require manual approval before deploying to production
3. **Separate staging and production workflows** — Push to `develop` deploys to staging, push to `main` deploys to production after tests pass
4. **Automated testing step** — Run HTML validation, link checking, or Lighthouse performance tests before deploying
5. **Slack/email notifications** — Alert the team on deployment success or failure
6. **Cache dependencies** — Cache AWS CLI or Node modules to speed up the runner
7. **Concurrency control** — Prevent multiple deployments running simultaneously:
```yaml
concurrency:
  group: production
  cancel-in-progress: false
```

---

### Q17: What is the `--cache-control` header and why does it matter for CloudFront?

**Answer:**  
`Cache-Control` is an HTTP header that tells CloudFront (and browsers) how long to cache a file. I set different cache strategies for different file types:

- **HTML files** — `public, max-age=0, must-revalidate` — Never cache. CloudFront always fetches fresh HTML from S3. This ensures users see the latest version immediately after deployment.
- **Assets (images, PDFs)** — `public, max-age=31536000` — Cache for 1 year. Images rarely change. Long caching means faster load times globally since CloudFront serves from edge locations without hitting S3.

Without correct cache headers, users might see a cached old version of your site for hours after deployment even after a successful `git push`. The `aws cloudfront create-invalidation` command clears CloudFront's edge cache, but browser cache is controlled by `Cache-Control` headers.

---

### Q18: What is a CloudFront invalidation and when is it needed?

**Answer:**  
A CloudFront invalidation tells CloudFront to remove cached copies of specified files from all its edge locations worldwide. Without invalidation, CloudFront serves the cached old version until the TTL expires — which could be hours.

```bash
aws cloudfront create-invalidation \
  --distribution-id E1NPERCOAFADC3 \
  --paths "/*"
```

`/*` invalidates all files. You can be more specific (e.g. `/cloud5ence.html`) to save invalidation costs — AWS charges for invalidations beyond 1,000 paths/month. For a small personal site invalidating `/*` is fine. For a large site with thousands of files you'd only invalidate what actually changed.

I run invalidation as the last step in every GitHub Actions deployment to ensure the fresh files are immediately served globally.

---

## QUICK REFERENCE — COMMANDS

```bash
# Terraform
terraform init                    # Initialise, download providers
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform output                  # Show output values
terraform state list              # List all managed resources
terraform destroy                 # DANGER — destroys everything

# AWS CLI
aws s3 ls s3://bucket-name/       # List bucket contents
aws s3 sync ./local/ s3://bucket/ # Sync files to S3
aws s3 cp file.html s3://bucket/  # Copy single file
aws cloudfront create-invalidation --distribution-id ID --paths "/*"
aws sts get-caller-identity       # Verify AWS credentials

# GitHub Actions
# Trigger manual run: GitHub → Actions → Select workflow → Run workflow
# View secrets: GitHub → Settings → Secrets and variables → Actions
```
