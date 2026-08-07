terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "joesparkman-terraform-state"
    key          = "creativespark-homepage/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

# Default provider - most resources (S3 buckets) live in us-east-2.
provider "aws" {
  region = "us-east-2"
}

# CloudFront and its ACM certificate must be managed from us-east-1,
# regardless of where the distribution's origins live.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
