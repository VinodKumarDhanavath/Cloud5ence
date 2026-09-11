# Cloud5ence — CX consulting website

The current application lives in `Cloud5ence_v1/`. It replaces the earlier
single-HTML portfolio with the consulting design from preview version 4.

## Local development

```sh
cd Cloud5ence_v1
npm install --global pnpm@11.19.0
pnpm install --frozen-lockfile
pnpm dev
```

Node >=22.13.0 is required; CI uses 22.16.0. Run `pnpm build`, then `pnpm preview`
to inspect the static production build locally. Read Cloud5ence_v1/README.md for
content editing, dependency details and the contact form's email-draft behavior.

## Existing AWS deployment

The GitHub Actions workflow builds on pull requests. After a merge/push to main,
it builds and uploads `Cloud5ence_v1/out/` to S3, then invalidates CloudFront.
Manual runs deploy only when main is selected. It uses the existing repository
secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET_NAME and
CLOUDFRONT_DISTRIBUTION_ID. Their presence and AWS permissions have not been
verified by this code change.

`pnpm build` produces both `index.html` and an identical `cloud5ence.html` alias.
This preserves the existing Terraform CloudFront default root object and error
fallback without requiring an infrastructure migration. All `_next` JavaScript
and CSS assets must be deployed; the previous extension whitelist is removed.
Versioned assets upload before HTML. Previous S3 objects are retained to avoid
breaking cached pages or existing links. Legacy files in the repository are not
included in the new output; only public/ assets and compiled application output
are published. Existing Terraform and legacy reference documents are retained.

No AWS infrastructure is created or changed by building locally or pushing the
redesign branch. Merging to main triggers the existing production deployment.

## Included design

Seven services, six anonymous client solution stories, Cloud5ence branding,
Vinod Dhanavath's original portrait, GSAP/Framer Motion interactions and responsive
layout. The contact dialog opens an email draft; it does not send or store leads.

Source design: published preview version 4, commit
c8c20ec44ff6aeb259b82110efb666801870b10c from the original Sites project.
