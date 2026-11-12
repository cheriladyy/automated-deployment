output "ec2_security_group_id" {
  description = "Security group of the ec2 Host"
  value       = aws_security_group.ec2_security_group.id
  depends_on  = [aws_vpc_security_group_ingress_rule.ec2_security_group_rule_ssh, aws_vpc_security_group_egress_rule.ec2_group_rule_egress]
}

output "ec2_iam_role_arn" {
  description = "IAM Role ARN of the ec2 Host"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_private_key_secret_id" {
  description = "ID of the AWS Secrets Manager secret storing the ec2 host's private SSH key"
  value       = aws_secretsmanager_secret.ec2_key.id
  sensitive   = true
  depends_on  = [aws_secretsmanager_secret_version.ec2_key_version]
}

output "ec2_public_ip" {
  description = "Public IP address of the ec2 host"
  value       = aws_instance.ec2.public_ip
  depends_on  = [aws_vpc_security_group_ingress_rule.ec2_security_group_rule_ssh, aws_vpc_security_group_egress_rule.ec2_group_rule_egress]
}
