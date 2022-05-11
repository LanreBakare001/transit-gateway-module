terraform {
  required_version = ">=0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.shared ]
    }
  }
}

resource "aws_ec2_transit_gateway" "tgw" {
  provider = aws.shared
  amazon_side_asn = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = merge(
    var.tags,
    {
      Name = "3Tgw-TGW"
    },
  )
}