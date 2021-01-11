terraform {
  required_version = ">= 0.12.0"
  backend "local" {}
}


variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.7.0"

  enable_dns_hostnames = true
  enable_dns_support   = true

  name = "vault-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Terraform = "true"
    App       = "vault"
  }
}

module "vault" {
  // source     = "giuliocalzolari/vault-consul/aws"
  source     = "../"
  vpc_id     = module.vpc.vpc_id
  aws_region = var.region

  environment = "dev"

  lb_subnets  = module.vpc.public_subnets
  ec2_subnets = module.vpc.public_subnets
  zone_name   = "demo.gc.crlabs.cloud"

  key_name          = "giulio.calzolari"
  size              = 3
  admin_cidr_blocks = ["93.71.71.0/24"]

  // kms_key_id = "ddbf32e1-1fd2-4686-9723-5cbf5505e932"

  arch          = "x86_64"
  instance_type = "t3.micro"

  extra_tags = {
    Terraform = "true"
    App       = "vault"
  }
}

output "module_vault" {
  value = module.vault
}
