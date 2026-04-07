# Cloud5ence — Customisation Guide

Quick reference for every common update you'll want to make.
Open `cloud5ence.html` in VS Code, use Ctrl+F / Cmd+F to find the section.

---

## 1. Replace your headshot

**File:** Put your photo in the repo root  
**Filename must be:** `WebsitePotrait.png`  
**Search for:** `WebsitePotrait.png` in cloud5ence.html (appears ~6 times)

Best photo: portrait, light/white background, upper body visible.

---

## 2. Add certification badge images

**When you download your badge from Credly (credly.com):**

| Cert | Save file as |
|---|---|
| AWS DevOps Engineer Professional | `aws-cert-badge.png` |
| Microsoft AZ-400 | `azure-cert-badge.png` |

Drop them in the repo root — they auto-appear on the Certifications page.  
The "Coming soon" ribbon disappears automatically once the image loads.

---

## 3. Add / replace strip photos

**Files:** `Ottawa.jpg`, `Workspace.jpg`, `working.jpg`, `Personal.jpg`, `Team.png`  
**Search for:** `strip-grid` or the filename in cloud5ence.html  

Replace any file with a new photo using the same filename — no code change needed.  
Want to add a 6th photo? Add `photo6.jpg` and copy a strip-item block in the HTML.

---

## 4. Add a new portfolio case study

**Search for:** `port-grid` in cloud5ence.html  
**Copy this block and paste inside the grid:**

```html
<a href="#" class="port-card">
  <div class="card-thumb" style="background:#deeafa">
    <span class="thumb-label" style="color:#0052a3;opacity:.3">TITLE</span>
    <span class="badge b-azure">Badge text</span>
  </div>
  <div class="card-body">
    <div class="card-title">Your Project Title</div>
    <div class="card-desc">Describe what you built and the outcome.</div>
    <div class="card-meta">Client · City · Year</div>
    <div class="card-cta">Read case study →</div>
  </div>
</a>
```

**Badge colour classes:** `b-azure` (blue) · `b-aws` (amber) · `b-k8s` (purple) · `b-tf` (green) · `b-sec` (red)

---

## 5. Add a new project card

**Search for:** `proj-grid` in cloud5ence.html  
**Copy this block:**

```html
<div class="proj-card">
  <span class="proj-badge b-aws">AWS</span>
  <div class="proj-title">Your Project Name</div>
  <div class="proj-desc">What it does and why it matters.</div>
  <div class="proj-meta">GitHub · description</div>
  <a href="https://github.com/VinodKumarDhanavath/YOUR-REPO" target="_blank" class="gh-link">
    View on GitHub
  </a>
</div>
```

---

## 6. Add a new certification (earned)

**Search for:** `Earned certifications` in cloud5ence.html  
Copy one of the 3 existing cert card blocks and update the content.  
Remove the "Coming soon" ribbon div once you have the badge image.

---

## 7. Add a new certification (in progress / planned)

**Search for:** `In progress` in cloud5ence.html  
Copy one of the dashed border cards and update name, body, and tags.

---

## 8. Write and publish a blog post

**Step 1** — Search for `blog-list` in cloud5ence.html  
**Step 2** — Find a blog item that says `onclick="return false;"` (coming soon)  
**Step 3** — Replace `href="#" onclick="return false;"` with `href="#" onclick="showPage('blogpost1');return false;"`  
**Step 4** — Remove the "Coming soon" badge span  
**Step 5** — Add a new page section at the bottom of the file:

```html
<div id="blogpost1" class="pg">
  <div class="wrap" style="max-width:720px">
    <a href="#" onclick="showPage('blog');return false;" style="color:var(--accent);font-size:13px">← Back to blog</a>
    <h1 style="font-family:'Outfit',sans-serif;font-size:36px;font-weight:800;margin:24px 0 12px">Your Article Title</h1>
    <p style="font-size:13px;color:var(--muted);margin-bottom:40px">April 2025 · 5 min read</p>
    <!-- Your article content here -->
    <p style="font-size:16px;color:#3a3a3a;line-height:1.85;margin-bottom:20px">First paragraph...</p>
  </div>
</div>
```

**Step 6** — Add `blogpost1:-1` to the JS map at the bottom of the file

---

## 9. Update contact details

**Search for:** `Vinod.dhanavath0418@gmail.com` — appears in contact page and form  
**Search for:** `linkedin.com/in/vinod-kumar-dhanavath` — LinkedIn URL

---

## 10. Update stats (years experience, etc.)

**Search for:** `stat-n` in cloud5ence.html — 4 stat cards in the black bar  
Change the numbers directly.

---

## 11. Update "My Story" article

**Search for:** `id="mystory"` in cloud5ence.html  
The article is plain HTML below that. Edit the text directly between the `<p>` tags.

---

## Push any change in 3 commands

```bash
git add .
git commit -m "content: describe what you changed"
git push origin main
# Auto-deploys to cloud5ence.com in ~60 seconds
```

---

## Come back to Claude for help

Start a new conversation with:
> "My repo is github.com/VinodKumarDhanavath/Cloud5ence — I want to [describe what you need]"

Claude will fetch the repo and help immediately.
