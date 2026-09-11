# Cloud5ence consulting website

A portable source export of the published version 4 design. The page, content,
CSS, portrait, logo, components, GSAP and Framer Motion code match the published
source. The build adapter has been changed from Sites/Vinext to standard Next.js
static export so this project can be hosted outside ChatGPT.

## Run locally

Install Node.js 22.16.0 or a compatible supported version >=22.13.0. Then:

```sh
npm install --global pnpm@11.19.0
pnpm install --frozen-lockfile
pnpm dev
```

Open http://localhost:3000. Dependencies are declared in package.json; exact
resolved versions are recorded in pnpm-lock.yaml. Keep the lockfile and
pnpm-workspace.yaml. Do not replace it with npm install or mix lockfiles.
The complete dependency catalog from the original is retained for reproducibility,
including unused starter libraries. node_modules is intentionally excluded;
installing downloads the platform-appropriate packages.

## Production build

```sh
pnpm build
pnpm preview
```

The output directory is `out/`. `pnpm preview` is a local check server only.
Publish the CONTENTS of `out/` to the root of your domain. The static output
contains all client JavaScript, CSS, and portrait assets. It needs no Node server,
Cloudflare account, API keys, database, or ChatGPT login at runtime.

For Git-connected static hosting, use:

- Project root: the folder containing this package.json
- Install: `pnpm install --frozen-lockfile`
- Build: `pnpm build`
- Output/publish directory: `out`
- Node: 22.16.0 or compatible >=22.13.0
- Package manager: pnpm 11.19.0
- Environment variables: none required

If your host auto-selects a framework, choose a static-site deployment when
available and ensure it publishes `out`, rather than expecting a Next server.
For a regular web host/cPanel, upload the built files into your domain's document
root (often public_html). Keep `_next/` intact. Do not upload the source as if it
were plain HTML. The export targets a domain root, such as https://cloud5ence.com/;
subdirectory hosting would need basePath and the portrait/favicon URLs adjusted.

## Put the source in an existing Git repository

1. Open your existing local website repository; commit or stash any work first.
2. Create a branch: `git switch -c redesign/cloud5ence-consulting`.
3. Copy this source folder's CONTENTS, including dotfiles, into the website
   application root. Keep the existing `.git` directory and remote. Replace the
   previous frontend files/configuration; do not leave a competing `src/app`,
   pages-router entrypoint, package-lock.json, or old build configuration active.
   For a monorepo, use the appropriate application directory.
4. Run `pnpm install --frozen-lockfile`, then `pnpm build` and `pnpm preview`.
5. Review `git diff` and `git status` before committing.
6. Commit and push:

```sh
git add .
git commit -m "Redesign Cloud5ence as a CX consulting company"
git push -u origin redesign/cloud5ence-consulting
```

Merge through your normal process. A Git push publishes only if your hosting
service is connected to that repository/branch and the settings above are set.
Otherwise upload the static output separately. Keep your domain DNS and existing
hosting settings unless your hosting provider requires a change.

## Edit content

| File | Purpose |
| --- | --- |
| app/content.ts | Seven services, six anonymous client solutions, credentials and resources |
| app/page.tsx | Page structure, GSAP/Framer Motion, dialogs and contact behavior |
| app/globals.css | Colors, typography, layout and responsive styling |
| app/layout.tsx | Browser title, SEO description and favicon metadata |
| public/vinod.png | Original portrait |
| public/favicon.svg | Cloud5ence favicon |
| components/ui/ | Included accessible UI primitives |
| vendor/ | Vendored styling and its license |

The logo wordmark is rendered in app/page.tsx with the AudioLines icon; it is not
an external image dependency. Typography uses Google Fonts (DM Sans and Manrope),
as in the preview, and falls back to system fonts if Google Fonts is blocked.
GSAP and Framer Motion are bundled locally, not loaded from a CDN.

## Current functionality

- Responsive consulting page, seven service tabs, six solution dialogs,
  industry links, interactive journey demo and four-step engagement tabs.
- GSAP scroll reveals and progress, Framer Motion interactions, reduced-motion
  support and a manual motion toggle.
- Contact creates a draft in the visitor's email application. It DOES NOT send
  through a server or store leads. A copy option is available if email does not open.
- Articles labeled "In the works" remain forthcoming, exactly as in the preview.
- External credential and social links still go to their original destinations.

## Validation and source

Exported from published Sites version 4, source commit
`c8c20ec44ff6aeb259b82110efb666801870b10c`.
The application files are byte-identical to that version; only packaging/build
configuration and documentation are adapted for independent hosting.
A production static build and TypeScript checks were run for this handoff.
Browser interaction/visual regression testing has not been performed for the
portable build, so inspect your own preview before switching your production site.

Static export documentation: https://nextjs.org/docs/app/guides/static-exports

## This repository

This application is under Cloud5ence_v1/. See ../README.md for the existing AWS
S3/CloudFront pipeline. The build also creates cloud5ence.html for compatibility
with the current CloudFront root object. No Terraform apply is needed.
