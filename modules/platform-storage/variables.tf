variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type    = string
  default = "openedx"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins for the OpenEdX storage bucket. Must be explicit domains — do NOT use [\"*\"] in production."

  validation {
    condition     = length(var.cors_allowed_origins) > 0
    error_message = "cors_allowed_origins must contain at least one origin."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

