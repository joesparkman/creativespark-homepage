locals {
  # Built from the account ID + distribution ID rather than a resource
  # reference, since this Terraform config does not own the distribution
  # (see the note at the top of cloudfront.tf).
  cloudfront_distribution_arn = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
}
