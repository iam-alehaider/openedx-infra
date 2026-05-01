
terraform {
  backend "s3" {
    bucket         = "openedx-terraform-state"
    key            = "live/dev/platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "openedx-terraform-locks"
    encrypt        = true
  }
}
