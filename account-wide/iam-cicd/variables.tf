
# account-wide/iam-cicd/variables.tf
# All values are hardcoded in main.tf for this account-wide layer.
# Variables are kept minimal — this layer runs once and rarely changes.

variable "region" {
  type    = string
  default = "us-east-1"
}

