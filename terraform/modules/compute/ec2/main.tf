data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720112718"] # Canonical Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2-key-pair-${var.environment}"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "ec2_key" {
  name                    = "ec2-host-ssh-private-key-${var.environment}"
  recovery_window_in_days = 0
  description             = "SSH private key for ec2 host (${var.environment})"
}

resource "aws_secretsmanager_secret_version" "ec2_key_version" {
  secret_id     = aws_secretsmanager_secret.ec2_key.id
  secret_string = tls_private_key.private_key.private_key_pem
}

# -----------------------------------------------------------------------------
# IAM (SSM describe)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name = "ec2Role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2Hostec2Profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

# -----------------------------------------------------------------------------
# ec2 Host
# -----------------------------------------------------------------------------

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name = "ec2-host-${var.environment}"
  }

 user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    APT="apt-get -y -o DPkg::Lock::Timeout=300"

    # t3.micro'da 1 GB RAM var, Jenkins kapanmasın diye 2 GB swap
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    # Docker + buildx + git + Java
    $APT update
    $APT install ca-certificates curl git fontconfig openjdk-21-jre docker.io docker-buildx
    systemctl enable --now docker
    usermod -aG docker ubuntu

    # Jenkins reposu ve kurulumu
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins-keyring.asc
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    $APT update
    $APT install jenkins

    # Jenkins'in geçici klasörü /tmp yerine diskte olsun
    mkdir -p /var/lib/jenkins/tmp
    chown jenkins:jenkins /var/lib/jenkins/tmp
    mkdir -p /etc/systemd/system/jenkins.service.d
    cat > /etc/systemd/system/jenkins.service.d/override.conf <<'CONF'
    [Service]
    Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.io.tmpdir=/var/lib/jenkins/tmp"
    CONF

    # Jenkins docker komutlarını çalıştırabilsin
    usermod -aG docker jenkins
    systemctl daemon-reload
    systemctl enable jenkins
    systemctl restart jenkins
  EOF

  lifecycle {
    ignore_changes = [ami]
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-host-security-group-${var.environment}"
  description = "ec2 Host Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "ec2-host-security-group-${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_security_group_rule_ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.ec2_security_group.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "SSH from trusted IP"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins" {
  for_each = toset(var.jenkins_allowed_cidrs)

  security_group_id = aws_security_group.ec2_security_group.id
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "Jenkins from trusted IP"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2_security_group.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Portfolio site from anywhere"
}

resource "aws_vpc_security_group_egress_rule" "ec2_group_rule_egress" {
  security_group_id = aws_security_group.ec2_security_group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
