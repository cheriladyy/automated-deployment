terraform {
  backend "s3" {
    bucket       = "gtopaloglu-tfstate"
    key          = "automated-deployment/core/dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
