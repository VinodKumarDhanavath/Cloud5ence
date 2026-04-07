# Cloud5ence — Vinod Kumar Dhanavath

> Personal portfolio + live AWS DevOps project  
> **[cloud5ence.com](https://cloud5ence.com)** · Ottawa, Canada

---

## Project status

- [x] Website designed and built (v1)
- [x] GitHub repo structured
- [x] GitHub Actions CI/CD workflow ready
- [x] Terraform IaC written (S3 + CloudFront + ACM + Route 53)
- [x] Photo strip with real photos
- [x] My Story article page
- [x] Certifications page with coming soon badges
- [ ] S3 bucket created
- [ ] CloudFront distribution live
- [ ] ACM certificate issued
- [ ] Route 53 hosted zone created
- [ ] GoDaddy nameservers updated to Route 53
- [ ] cloud5ence.com live
- [ ] GitHub secrets added (auto-deploy active)
- [ ] AWS cert badge image added (aws-cert-badge.png)
- [ ] Azure cert badge image added (azure-cert-badge.png)
- [ ] Contact form backend (Lambda + SES)
- [ ] Blog articles written and published

---

## Files in this repo

| File | Purpose |
|---|---|
| `cloud5ence.html` | Complete website — all 7 pages |
| `WebsitePotrait.png` | Hero headshot |
| `Ottawa.jpg` | Photo strip — Ottawa |
| `Workspace.jpg` | Photo strip — Workspace |
| `working.jpg` | Photo strip — Working |
| `Personal.jpg` | Photo strip — Personal |
| `Team.png` | Photo strip — Team |
| `Claud101_Cert.pdf` | Anthropic Claude 101 certificate |
| `Vinod Kumar Dhanavath New - DevOps.pdf` | CV / Resume |
| `aws-cert-badge.png` | ← ADD THIS from Credly |
| `azure-cert-badge.png` | ← ADD THIS from Credly |
| `CUSTOMISE.md` | Guide for all future updates |
| `.github/workflows/deploy.yml` | Auto-deploy on push to main |
| `infra/main.tf` | Terraform — full AWS infrastructure |
| `infra/variables.tf` | Terraform variables |

---

## Local development

```bash
# VS Code + Live Server extension
# Right-click cloud5ence.html → Open with Live Server
# http://127.0.0.1:5500/cloud5ence.html
```

---

## Deploy to AWS

See full step-by-step in `CUSTOMISE.md` and the previous session history.

```bash
cd infra/
terraform init && terraform plan && terraform apply
# Copy nameservers output → paste into GoDaddy
# Copy cloudfront_distribution_id → GitHub secret
# git push → auto-deploys in 60 seconds
```

---

## Author

**Vinod Kumar Dhanavath** · DevOps & Cloud Engineer · Ottawa, Canada  
[cloud5ence.com](https://cloud5ence.com) · [LinkedIn](https://www.linkedin.com/in/vinod-kumar-dhanavath/) · [GitHub](https://github.com/VinodKumarDhanavath)
