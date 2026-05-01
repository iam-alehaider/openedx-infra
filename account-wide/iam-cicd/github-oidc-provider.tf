#=======================================================================
# GitHub Actions OIDC Provider
#
# This must exist in the AWS account before any GitHub Actions workflow
# can assume an IAM role via OIDC. It is created ONCE account-wide.
#
# If you get "InvalidIdentityToken" errors in GitHub Actions, this
# resource is either missing or was created with the wrong thumbprint.
# The thumbprint below is stable — it is pinned to GitHub's OIDC
# certificate chain and does not need updating when GitHub rotates
# their signing cert (AWS validates by audience, not thumbprint, for
# GitHub Actions specifically).
#=======================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — stable, no rotation needed.
  # Source: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name      = "github-actions-oidc-provider"
    ManagedBy = "terraform"
    Purpose   = "GitHub Actions OIDC federation"
  }
}

