variable "aws_account_id" {
  description = "AWS account ID that owns this infrastructure."
  type        = string
  default     = "196403805571"
}

variable "domain_name" {
  description = "Root domain served by this site."
  type        = string
  default     = "joesparkman.com"
}

variable "site_buckets" {
  description = "S3 buckets that hold the static site, keyed by their bucket name."
  type        = set(string)
  default     = ["www.joesparkman.com", "app.joesparkman.com"]
}

variable "github_repo" {
  description = "GitHub repo (owner/name) allowed to assume the deploy role via OIDC."
  type        = string
  default     = "joesparkman/creativespark-homepage"
}

variable "github_deploy_branch" {
  description = "Branch allowed to assume the deploy role."
  type        = string
  default     = "main"
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID this site is served through. Owned by the quickbite project's Terraform, referenced here by ID only so the deploy role can invalidate it."
  type        = string
  default     = "E3HHU0R4DHMA69"
}
