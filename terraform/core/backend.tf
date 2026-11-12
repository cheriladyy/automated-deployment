terraform {
  backend "s3" {
    bucket       = "gtopaloglu-terraform-state-bucket"
    key          = "automated-deployment/core/dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
