# Jenkins'in self-service ortamlarını açıp kapatabilmesi için EC2 instance profile üzerinden aldığı izinler.

locals {
  state_bucket = "gtopaloglu-tfstate"
}

data "aws_iam_policy_document" "jenkins_environments" {
  # Ortamların EC2 ve security group kaynakları, sadece bu region
  statement {
    sid       = "Ec2InRegion"
    actions   = ["ec2:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]
  }

  # Ortamların state dosyaları: okuma, yazma, silme
  statement {
    sid       = "EnvironmentStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/automated-deployment/environments/*"]
  }

  # Core state'i: sadece okuma (terraform_remote_state için). Jenkins core'u değiştiremez.
  statement {
    sid       = "CoreStateReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/automated-deployment/core/*"]
  }

  # Ansible'ın kullanacağı SSH anahtarı
  statement {
    sid       = "ReadEnvironmentsSshKey"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.environments_key.arn]
  }
}

resource "aws_iam_role_policy" "jenkins_environments" {
  name   = "jenkins-self-service-environments"
  role   = module.compute.ec2_iam_role_name
  policy = data.aws_iam_policy_document.jenkins_environments.json
}

