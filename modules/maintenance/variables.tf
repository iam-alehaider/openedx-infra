

variable "project" {
  type    = string
  default = "openedx"
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "bucket_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where the maintenance S3 bucket is created. Affects the Route53 zone ID."
}
