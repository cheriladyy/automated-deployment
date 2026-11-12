output "terraform_deployer_role_arn" {
  description = "AWS_ROLE_ARN secret of the automated-deployment repo"
  value       = aws_iam_role.terraform_deployer.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}
