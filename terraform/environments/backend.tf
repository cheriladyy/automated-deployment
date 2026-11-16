terraform {
  backend "s3" {
    bucket       = "gtopaloglu-tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
    # terraform init -backend-config="key=automated-deployment/environments/<env_name>/terraform.tfstate"
  }
}