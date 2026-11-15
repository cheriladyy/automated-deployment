variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "env_name" {
  description = "Unique environment name"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.env_name))
    error_message = "env_name must be 3-21 chars: lowercase letters, digits, '-', starting with a letter."
  }
}

variable "template" {
  description = "Environment template"
  type        = string

  validation {
    condition     = contains(["webserver", "database", "fullstack"], var.template)
    error_message = "template must be one of: webserver, database, fullstack."
  }
}

variable "size" {
  description = "Environment size"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "size must be one of: small, medium, large."
  }
}

variable "ttl_days" {
  description = "Days until auto-destroy (1-7)"
  type        = number
  default     = 1

  validation {
    condition     = var.ttl_days >= 1 && var.ttl_days <= 7 && floor(var.ttl_days) == var.ttl_days
    error_message = "ttl_days must be an integer between 1 and 7."
  }
}

variable "owner" {
  description = "Who requested the environment (Jenkins user)"
  type        = string
  default     = "unknown"
}
