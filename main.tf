provider "aws" {
  alias   = "account_one"
  profile = "mprofile"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "account_two"
  profile = "sprofile"
  region  = "us-west-2"
}

data "aws_availability_zones" "available" {
  provider = aws.account_one
  state    = "available"
}

data "aws_caller_identity" "account_one" {
  provider = aws.account_two
}

locals {
  tags = {
    "project" = "TGW sample"
  }
}

module "transit_gateway_ram" {
  source        = "./modules/transit-gateway-ram"
  ram_name      = "ram-eample-l"
  tags          = local.tags
  ram_principal = data.aws_caller_identity.account_one.account_id
  providers = {
    aws.one = aws.account_one
    aws.two = aws.account_two
  }
}

module "vpc_attachments" {
  source          = "./modules/vpc-tgw-attachment"
  transit_gateway = module.transit_gateway_ram.transit_gateway
  tags          = local.tags
  vpc_one_cidr = "10.0.0.0/16"
  vpc_two_cidr = "101.0.0.0/16"
  providers = {
    aws.one = aws.account_one
    aws.two = aws.account_two
  }
}
