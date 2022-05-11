provider "aws" {
  alias   = "shared_account_east_1"
  profile = "mprofile"
  region  = "us-east-2"
}

provider "aws" {
  alias   = "account_one"
  profile = "mprofile"
  region  = "us-east-2"
}

data "aws_caller_identity" "account_one" {
  provider = aws.account_one
}

locals {
  tags = {
    "project" = "3gTgw"
  }
}

module "transit_gateway_one" {
  source  = "./modules/transit-gateway"
  tgw_asn = 65534
  tags    = local.tags
  providers = {
    aws.shared = aws.shared_account_east_1
  }
}

module "resource_access_manager_1" {
  source   = "./modules/resource-access-manager"
  ram_name = "3G-resource-access-manager"
  ram_principals = [
    data.aws_caller_identity.account_one.account_id
  ]
  tgws = [
    module.transit_gateway_one.transit_gateway_arn
  ]
  tags = local.tags
  providers = {
    aws.shared        = aws.shared_account_east_1
    aws.child_account = aws.account_one
  }
}

module "vpc_account_1" {
  source                 = "./modules/virtual-private-cloud"
  transit_gateway        = module.transit_gateway_one.transit_gateway_id
  tags                   = local.tags
  vpc_cidr               = "10.0.0.0/16"

  providers = {
    aws.shared        = aws.shared_account_east_1
    aws.child_account = aws.account_one
  }
}
