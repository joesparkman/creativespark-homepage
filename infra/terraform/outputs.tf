output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution the deploy role can invalidate (owned by the quickbite Terraform project, referenced here by ID only)."
  value       = local.cloudfront_distribution_arn
}

output "github_actions_deploy_role_arn" {
  description = "Role ARN to reference in the GitHub Actions workflow's role-to-assume."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.site.arn
}
