
output "github_ecr_push_role_arn" {
  description = "ARN of the IAM role used by GitHub Actions to push images to ECR"
  value       = aws_iam_role.github_ecr_push.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the IAM role used by GitHub Actions to deploy to EKS"
  value       = aws_iam_role.github_deploy.arn
}

