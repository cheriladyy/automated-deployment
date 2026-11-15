# Ansible bağlantısı için tüm self-service ortamlarının ortak SSH anahtarı 
resource "tls_private_key" "environments" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "environments" {
  key_name   = "environments-key"
  public_key = tls_private_key.environments.public_key_openssh
}

# İsim, deployer IAM policy'sindeki "ec2-host-ssh-private-key-*" iznine uyuyor
# GitHub Actions deployer rolü (bootstrap'taki IAM policy) SM'da sadece ec2-host-ssh-private-key-* ile başlayan isimlere izin veriyor 

resource "aws_secretsmanager_secret" "environments_key" {
  name                    = "ec2-host-ssh-private-key-environments"
  recovery_window_in_days = 0
  description             = "SSH private key for self-service environments"
}

resource "aws_secretsmanager_secret_version" "environments_key" {
  secret_id     = aws_secretsmanager_secret.environments_key.id
  secret_string = tls_private_key.environments.private_key_pem
}