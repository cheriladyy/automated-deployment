output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_default_security_group_id" {
  description = "Default security group ID of the VPC"
  value       = module.vpc.vpc_default_security_group_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "ec2_public_ip" {
  description = "Public IP address of the ec2"
  value       = module.compute.ec2_public_ip
}

output "ec2_security_group_id" {
  description = "Security group of the ec2"
  value       = module.compute.ec2_security_group_id
}

output "ec2_private_key_secret_id" {
  description = "Secrets Manager secret ID holding the ec2 SSH private key"
  value       = module.compute.ec2_private_key_secret_id
  sensitive   = true
}
