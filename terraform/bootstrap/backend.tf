terraform {
  backend "s3" {
    bucket       = "gtopaloglu-tfstate"
    key          = "automated-deployment/bootstrap/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
