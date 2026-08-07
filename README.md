# creativespark-homepage

Source for [www.joesparkman.com](https://www.joesparkman.com) — a static
portfolio site showcasing cloud applications and automation projects, plus
the interactive demo pages for several of them (served from
`app.joesparkman.com`).

## Stack

HTML/CSS/JavaScript · Terraform · Amazon S3 · CloudFront · ACM ·
GitHub Actions (OIDC) · IAM

## How it deploys

Every push to `main` triggers `.github/workflows/deploy.yml`, which:

1. Assumes an IAM role via GitHub Actions OIDC (no long-lived AWS keys).
2. Syncs the site to both the `www.joesparkman.com` and `app.joesparkman.com`
   S3 buckets.
3. Invalidates the CloudFront distribution cache.

The underlying AWS infrastructure (S3 buckets, ACM certificate, the OIDC
deploy role) is managed with Terraform in `infra/terraform/` — see
`infra/terraform/README.md` for details on what is and isn't owned there.

## Repo layout

```
index.html              Homepage — hero, project cards, app demo videos
portfolio-story.html    "Portfolio Website" project story page
portfolio-architecture.html   "Portfolio Website" project architecture diagram
biometric/, call-triage/, quickbite/, pet-recipe-app/
                         Per-project App / Story / Visual Diagram pages,
                         served under app.joesparkman.com
infra/terraform/        S3, CloudFront, ACM, and OIDC deploy role
```

Each featured project on the homepage links out to its own dedicated
GitHub repo — this repo only holds the site shell and the static per-project
demo pages, not the projects' application code or infrastructure.
