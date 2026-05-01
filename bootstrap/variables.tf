
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  default     = "openedx-terraform-state"
  description = "Must be globally unique in S3. Change to match your company name."
}

variable "lock_table_name" {
  type    = string
  default = "openedx-terraform-locks"
}
