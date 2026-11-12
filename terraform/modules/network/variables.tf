variable "environment" {
  description = "Environment name"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones (one per public subnet)"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(var.availability_zones)
    error_message = "public_subnets and availability_zones must have the same number of elements."
  }
}
