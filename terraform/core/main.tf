module "vpc" {
  source = "../modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "network" {
  source = "../modules/network"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
}

module "compute" {
  source = "../modules/compute/ec2"

  environment       = var.environment
  aws_region        = var.aws_region
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  allowed_ssh_cidrs = var.ec2_allowed_ssh_cidrs
  jenkins_allowed_cidrs = var.jenkins_allowed_cidrs
}
