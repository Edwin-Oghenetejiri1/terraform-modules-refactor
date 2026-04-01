########################################
# Terraform & Backend Configuration
########################################
terraform {
  backend "s3" {
    bucket         = "tejiri-my-tf-test-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tejiri-table"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

########################################
# AWS Provider
########################################
provider "aws" {
  region = "us-east-1"
}

########################################
# Network Module
########################################
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_1_cidr = "10.0.1.0/24"
  public_subnet_2_cidr = "10.0.2.0/24"
  az_1                 = "us-east-1a"
  az_2                 = "us-east-1b"
}

########################################
# Compute Module
########################################
module "compute" {
  source = "./modules/compute"

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
}

########################################
# Database Module
########################################
module "database" {
  source = "./modules/database"

  subnet_ids  = module.vpc.public_subnet_ids
  db_name     = "appdb"
  db_username = "admin"
  db_password = "password123"
}