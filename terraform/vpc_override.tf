# Override VPC module attributes
locals {
  vpc_overrides = {
    create_igw = false
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  # Use the overrides
  create_igw = local.vpc_overrides.create_igw
}
