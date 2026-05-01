

output "github_deploy_role_arn_dev"     { value = module.iam_cicd_dev.github_deploy_role_arn }
output "github_deploy_role_arn_staging" { value = module.iam_cicd_staging.github_deploy_role_arn }
output "github_deploy_role_arn_prod"    { value = module.iam_cicd_prod.github_deploy_role_arn }
output "github_ecr_push_role_arn"       { value = module.iam_cicd_prod.github_ecr_push_role_arn }
