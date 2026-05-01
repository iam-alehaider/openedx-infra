
# account-wide/ecr/variables.tf
# ECR is account-wide (not per-environment).
# All environments share the same registry; image tags differentiate envs.

variable "region" {
  type    = string
  default = "us-east-1"
}

