
variable "project" {
  type    = string
  default = "openedx"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "One shared maintenance page serves all environments."
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  type    = map(string)
  default = { Scope = "account-wide" }
}

