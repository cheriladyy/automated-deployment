terraform {
  backend "s3" {
    bucket       = "gtopaloglu-terraform-state-bucket"
    key          = "automated-deployment/bootstrap/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
