# time_static ortamın oluşturulma anını sabitler. Expiration date belirlemen için önce ne zaman oluşturulduğunu bilmen lazım :)
# This prevents differences caused by using the timestamp() function.
resource "time_static" "created" {}

locals {
    expires_at = timeadd(time_static.created.rfc3339, "${var.ttl_days * 24}h")

    instance_types = {
        small  = "t3.micro"
        medium = "t3.small"
        large  = "t3.medium"

    }

    template_ports = {
        webserver = [80]
        database  = [5432]
        fullstack = [80, 5432] 
    }
}

# Core'daki ortak VPC ve subnet'ler
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "gtopaloglu-terraform-state-bucket"
    key    = "automated-deployment/core/dev/terraform.tfstate"
    region = "eu-west-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "env" {
  name   = "env-${var.env_name}"
  vpc_id = data.terraform_remote_state.core.outputs.vpc_id
}

# Jenkins'in Ansible için SSH yapabilmesi gerekiyor. O yüzden Jenkins'in çalıştığu makinenin sg'sini referans verdik.
resource "aws_vpc_security_group_ingress_rule" "ssh_from_jenkins" {
  security_group_id            = aws_security_group.env.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = data.terraform_remote_state.core.outputs.ec2_security_group_id
}

# locals.tf dosyasında belirlediğimiz template'e göre sg ingress portlarını açıyor.
resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = toset([for p in local.template_ports[var.template] : tostring(p)])

  security_group_id = aws_security_group.env.id
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.env.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "env" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_types[var.size]
  subnet_id              = data.terraform_remote_state.core.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.env.id]
  key_name               = var.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name      = "env-${var.env_name}"
    ExpiresAt = local.expires_at
  }
}