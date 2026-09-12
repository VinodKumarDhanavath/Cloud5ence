# Google Analytics 4 setup

Standard GA4 is available at no charge. This integration adds no package,
AWS resource or paid analytics subscription. Existing hosting and CI usage still
apply. Paid Analytics 360, BigQuery export and advertising are not configured.

## Activate after review

1. In Google Analytics, create/select a property for Cloud5ence and a **Web**
   data stream for `https://cloud5ence.com`.
2. Open **Admin → Data streams → your web stream**, and copy the Measurement ID
   beginning `G-`. This is a public identifier, not a secret.
3. In this repository open **Settings → Secrets and variables → Actions →
   Variables**. Add `NEXT_PUBLIC_GA_MEASUREMENT_ID` with that value.
4. Review the PR, pass its build check, and merge through the existing branch
   protection/review process. The main workflow builds the static website with
   this variable, uploads to S3 and invalidates CloudFront.
5. Visit the live site, then check the property's **Realtime** report. A normal
   page load sends one automatic page_view through the Google tag config.
   Regular reports may take longer to populate. Ad blockers may prevent collection.

No ID or an invalid ID means no analytics script is loaded. A draft PR alone
does not activate tracking. The ID is embedded at build time: changing or removing
it requires a fresh main deployment. Existing data stays in the GA4 property.

The code only loads analytics on `cloud5ence.com` and `www.cloud5ence.com`;
localhost, private previews and other domains are excluded. Local setup can copy
`.env.example` to `.env.local`, but localhost remains deliberately untracked.
The supplied example leaves the value empty rather than using a fake live ID.

## What this collects

The Google tag supplies standard page-view, session and user metrics, device
information and approximate geographic reporting. Google signals and advertising
personalization signals are disabled in the tag configuration. No custom user ID,
contact-form contents, email address or lead-submission event is added by this
implementation. The existing contact form opens an email draft; it is not evidence
that someone sent an enquiry. This PR does not add consent-management UI; review
visitor consent and the website's analytics disclosure before activating the ID.

Use acquisition reports for traffic sources and demographic details for country,
region and city. Locations are approximate. User/session metrics are estimates,
not an exact count of individual people. This single-page site currently records
the page visit; service tabs and solution dialogs are not separate page views.

For a Facebook campaign, a link such as
`https://cloud5ence.com/?utm_source=facebook&utm_medium=social&utm_campaign=launch`
helps identify that traffic. Keep personal information out of campaign URLs.

## References

- Pricing: https://marketingplatform.google.com/about/analytics/
- Measurement ID: https://support.google.com/analytics/answer/9539598
- Google tag: https://developers.google.com/tag-platform/gtagjs
