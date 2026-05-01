variable "project" {
  type    = string
  default = "openedx"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cors_allowed_origins" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
