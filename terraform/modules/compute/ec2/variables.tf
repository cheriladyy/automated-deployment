variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids"
  type        = list(string)
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the ec2 host. Empty list = SSM only."
  type        = list(string)
  default     = []
}

variable "jenkins_allowed_cidrs" {
  description = "CIDR blocks allowed to access Jenkins 8080"
  type        = list(string)
}

variable "instance_type" {
  description = "ec2 host instance type"
  type        = string
  default     = "t3.micro"
}
