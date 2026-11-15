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

output "environments_key_name" {
  description = "Key pair name used by self-service environments"
  value       = aws_key_pair.environments.key_name
}

output "environments_key_secret_id" {
  description = "Secrets Manager secret holding the environments SSH private key"
  value       = aws_secretsmanager_secret.environments_key.id
}
