
variable "project" {
  type    = string
  default = "openedx"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "database_subnets" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "flow_log_traffic_type" {
  type    = string
  default = "REJECT"
}

variable "flow_log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
