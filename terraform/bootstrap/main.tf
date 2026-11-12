locals {
  sub_prefixes = [
    "repo:${var.github_owner}/${var.github_repo}",
    "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}",
  ]

  # Sadece main branch'e push
  allowed_subs = [for prefix in local.sub_prefixes : "${prefix}:ref:refs/heads/main"]

  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "gtopaloglu-terraform-state-bucket"
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# GitHub OIDC provider
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --------------------------------------------------------------------
# GitHub Actions deployer role 
# --------------------------------------------------------------------

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subs
    }
  }
}

resource "aws_iam_role" "terraform_deployer" {
  name                 = "github-actions-terraform-deployer"
  description          = "Assumed by GitHub Actions to run Terraform"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
}

# --------------------------------------------------------------------
# Deployer permissions: sadece terraform/core'un yönettiği kaynaklar
# --------------------------------------------------------------------

data "aws_iam_policy_document" "terraform_deployer" {
  # VPC, subnet, IGW, route table, SG, key pair, EC2: sadece tek region
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

  # Sadece ec2Role-* rolünü yönetebilir
  statement {
    sid = "ManageEc2Role"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2Role-*"]
  }

  # O role sadece SSM policy'si takabilir
  statement {
    sid       = "AttachOnlySsmPolicy"
    actions   = ["iam:AttachRolePolicy"]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2Role-*"]

    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    }
  }

  statement {
    sid = "ManageInstanceProfile"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = ["arn:aws:iam::${local.account_id}:instance-profile/ec2Hostec2Profile-*"]
  }

  # Rolü sadece EC2'ye verebilir
  statement {
    sid       = "PassRoleToEc2"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/ec2Role-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Sadece SSH key secret'ı
  statement {
    sid = "ManageSshKeySecret"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:ec2-host-ssh-private-key-*",
    ]
  }

  # Sadece core state'i (bootstrap state'ine erişemez)
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]
  }

  statement {
    sid       = "CoreStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/automated-deployment/core/*"]
  }
}

resource "aws_iam_role_policy" "terraform_deployer" {
  name   = "terraform-core-deploy"
  role   = aws_iam_role.terraform_deployer.id
  policy = data.aws_iam_policy_document.terraform_deployer.json
}
