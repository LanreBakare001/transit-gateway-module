terraform {
  required_version = ">=0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.one, aws.two ]
    }
  }
}

resource "aws_ec2_transit_gateway" "tgw" {
  provider = aws.one
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags                            = var.tags
}

resource "aws_ram_resource_share" "ram" {
  provider = aws.one
  name = "ram-share-example"
  tags = var.tags
}

# Share the transit gateway...
# resource "aws_ram_resource_association" "ram_association" {
#   provider = aws.one
#   resource_arn       = aws_ec2_transit_gateway.tgw.arn
#   resource_share_arn = aws_ram_resource_share.ram.id
# }

# # Share with the second account.
# resource "aws_ram_principal_association" "ram_principal" {
#   provider = aws.one
#   principal          = var.ram_principal
#   resource_share_arn = aws_ram_resource_share.ram.id
# }