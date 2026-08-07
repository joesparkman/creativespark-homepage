# ─────────────────────────────────────────────────────────────
# www.joesparkman.com - primary site bucket, origin for CloudFront
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "www" {
  bucket = "www.joesparkman.com"
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "www" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "www" {
  bucket = aws_s3_bucket.www.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.www.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.www]
}

# ─────────────────────────────────────────────────────────────
# app.joesparkman.com - secondary bucket, kept in sync with the
# same static assets (aliased on the same CloudFront distribution)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket = "app.joesparkman.com"

  # This bucket already carries tags from an earlier pet-recipe-app
  # Terraform project (not present in this repo/state). Preserved as-is
  # rather than stripped, so this config doesn't fight that project for
  # ownership of the tags.
  tags = {
    App         = "pet-recipe"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "jojob"
    Project     = "pet-recipe-app"
  }
}

resource "aws_s3_bucket_website_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  index_document {
    suffix = "index.html"
  }
}

# NOTE: this bucket blocks public ACLs while still allowing the public-read
# bucket policy below (BlockPublicPolicy/RestrictPublicBuckets are false).
# That's the actual live configuration - www and app were provisioned at
# different times and drifted slightly; left as-is rather than "fixed"
# to avoid an unplanned behavior change on the first apply.
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.app.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.app]
}
