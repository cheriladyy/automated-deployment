variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "gtopaloglu"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "github_owner" {
  description = "GitHub user or organization name"
  type        = string
}

variable "github_owner_id" {
  description = "Numeric GitHub user ID"
  type        = string
}

variable "github_repo" {
  description = "Repository that is allowed to assume the deployer role"
  type        = string
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID"
  type        = string
}
