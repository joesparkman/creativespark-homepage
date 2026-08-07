# Separate deploy role for the dev environment, scoped only to the dev
# bucket and dev distribution - kept independent from the prod deploy
# role (github-actions-creativespark-deploy) so a compromised or
# misconfigured dev pipeline can never touch production resources.

data "aws_iam_policy_document" "github_actions_dev_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_dev_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy_dev" {
  name        = "github-actions-creativespark-deploy-dev"
  description = "Deploy role for GitHub Actions - dev.joesparkman.com staging mirror, scoped to the dev bucket + dev distribution only"

  assume_role_policy = data.aws_iam_policy_document.github_actions_dev_trust.json
}

data "aws_iam_policy_document" "deploy_dev_scoped_permissions" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.dev.arn]
  }

  statement {
    sid    = "SyncObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.dev.arn}/*"]
  }

  statement {
    sid       = "InvalidateCache"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.dev.arn]
  }
}

resource "aws_iam_role_policy" "deploy_dev_scoped_permissions" {
  name   = "deploy-dev-scoped-permissions"
  role   = aws_iam_role.github_actions_deploy_dev.id
  policy = data.aws_iam_policy_document.deploy_dev_scoped_permissions.json
}
