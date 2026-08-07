# NOTE: The CloudFront distribution itself (E3HHU0R4DHMA69) is intentionally
# NOT managed here. It's already owned by the "quickbite" project's own
# Terraform state (aws_cloudfront_distribution.frontend, same state bucket,
# key "quickbite/terraform.tfstate"). Managing it from two separate Terraform
# configs risks one silently reverting the other's changes on apply, so this
# config only tracks the pieces that are actually free of that conflict: the
# CloudFront Function, the ACM certificate, the origin S3 buckets, and the
# GitHub Actions deploy role.
#
# See var.cloudfront_distribution_id / local.cloudfront_distribution_arn in
# iam.tf for how the deploy role's invalidation permission still references
# the distribution by ARN without owning it.

# Rewrites extensionless /quickbite/* SPA paths to /quickbite/index.html so
# React Router's client-side routes resolve on a direct hit/refresh.
resource "aws_cloudfront_function" "quickbite_spa_routing" {
  name    = "quickbite-spa-routing"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite /quickbite/* SPA paths (extensionless or .html) to index.html for React Router"
  publish = true

  code = <<-EOT
    function handler(event) {
        var request = event.request;
        var uri = request.uri;

        if (uri.indexOf('/quickbite/') === 0 && uri !== '/quickbite/index.html') {
            var lastSegmentStart = uri.lastIndexOf('/');
            var lastSegment = uri.slice(lastSegmentStart);
            var hasRealExtension = lastSegment.indexOf('.') !== -1 && lastSegment.slice(-5) !== '.html';

            if (!hasRealExtension) {
                request.uri = '/quickbite/index.html';
            }
        }

        return request;
    }
  EOT
}
