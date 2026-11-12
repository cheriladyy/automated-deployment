variable "project" {
  description = "Project name"
  type        = string
}

variable "owners" {
  description = "Owner name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones (one per public subnet)"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "ec2_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the ec2"
  type        = list(string)
}

variable "jenkins_allowed_cidrs" {
  description = "CIDR blocks allowed to access Jenkins 8080"
  type        = list(string)
}