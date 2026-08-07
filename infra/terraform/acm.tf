# ACM certificate for the CloudFront distribution. Must live in us-east-1.
#
# DNS for joesparkman.com is managed at the registrar (GoDaddy), not Route 53,
# so there is no aws_route53_record / aws_acm_certificate_validation here -
# the validation CNAME was created manually at the registrar. This resource
# just brings the already-issued certificate under management; Terraform
# will not attempt to re-validate it.

resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name               = "joesparkman.com"
  subject_alternative_names = ["*.joesparkman.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
