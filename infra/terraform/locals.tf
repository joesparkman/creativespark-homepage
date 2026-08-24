locals {
  # Built from the account ID + distribution ID rather than a resource
  # reference, since this Terraform config does not own the distribution
  # (see the note at the top of cloudfront.tf).
  cloudfront_distribution_arn = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"

  # GitHub now appends immutable entity IDs to the OIDC sub claim whenever a
  # repo has been renamed or re-created (e.g. "joesparkman@106938486" instead
  # of "joesparkman"), so the trust policy wildcards past those optional
  # "@<id>" suffixes rather than matching the plain "owner/repo" string.
  github_owner     = split("/", var.github_repo)[0]
  github_repo_name = split("/", var.github_repo)[1]
}
