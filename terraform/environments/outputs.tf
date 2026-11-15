output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.env.id
}

output "public_ip" {
  description = "Public IP"
  value       = aws_instance.env.public_ip
}

output "private_ip" {
  description = "Private IP"
  value       = aws_instance.env.private_ip
}

output "expires_at" {
  description = "Auto-destroy time"
  value       = local.expires_at
}