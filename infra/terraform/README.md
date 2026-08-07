# Terraform - creativespark-homepage infrastructure

Manages the real AWS resources behind `joesparkman.com`:

- S3 buckets `www.joesparkman.com` and `app.joesparkman.com` (static website hosting, public-read policy)
- ACM certificate for `joesparkman.com` / `*.joesparkman.com` (us-east-1)
- The `quickbite-spa-routing` CloudFront Function
- The GitHub Actions OIDC provider + deploy role (`github-actions-creativespark-deploy`), scoped to S3 sync and CloudFront invalidation only

## Deliberately NOT managed here

- **The CloudFront distribution itself** (`E3HHU0R4DHMA69`). It's already owned by the `quickbite` project's own Terraform state (same state bucket, key `quickbite/terraform.tfstate`, resource `aws_cloudfront_distribution.frontend`). This config references it only by ARN (`local.cloudfront_distribution_arn` in `locals.tf`) so the deploy role can invalidate it without two configs fighting for ownership.
- **DNS**. `joesparkman.com` is managed at the registrar (GoDaddy), not Route 53 - there's no hosted zone in this account.
- Anything belonging to the individual project apps (QuickBite's Lambdas/DynamoDB/Cognito, the pet-recipe-app resources, etc.) - those live in their own repos/state.

## State

Remote state lives in `s3://joesparkman-terraform-state/creativespark-homepage/terraform.tfstate` (versioned, encrypted, private). That bucket is shared with at least one other project's state (`quickbite/`) - always check `terraform plan` output carefully before applying; if you see a resource you don't recognize being added/destroyed, stop and figure out why before proceeding, since it likely means another project's Terraform also touches it.

## Usage

```
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Requires AWS credentials for account `196403805571` with permissions over S3, ACM, CloudFront (Functions only), and IAM.
