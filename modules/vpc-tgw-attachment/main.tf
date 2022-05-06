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

data "aws_availability_zones" "available_one" {
  provider = aws.one
  state = "available"
}

data "aws_availability_zones" "available_two" {
  provider = aws.two
  state = "available"
}

resource "aws_vpc" "vpc_one" {
  provider = aws.one
  cidr_block = var.vpc_one_cidr
  tags       = var.tags
}

resource "aws_vpc" "vpc_two" {
  provider = aws.two
  cidr_block = var.vpc_two_cidr
  tags       = var.tags
}



resource "aws_internet_gateway" "gw_one" {
  provider = aws.one
  vpc_id = aws_vpc.vpc_one.id
  tags = var.tags
}

resource "aws_internet_gateway" "gw_two" {
  provider = aws.two
  vpc_id = aws_vpc.vpc_two.id
  tags = var.tags
}

resource "aws_subnet" "public_one" {
    provider = aws.one
    count = 2
  availability_zone = data.aws_availability_zones.available_one.names[count.index]
  vpc_id            = aws_vpc.vpc_one.id
  cidr_block        = cidrsubnet(aws_vpc.vpc_one.cidr_block, 8, count.index)
  tags = var.tags
}

resource "aws_subnet" "public_two" {
    provider = aws.two
    count = 2
  availability_zone = data.aws_availability_zones.available_two.names[count.index]
  vpc_id            = aws_vpc.vpc_two.id
  cidr_block        = cidrsubnet(aws_vpc.vpc_two.cidr_block, 8, count.index)
  tags = var.tags
}

resource "aws_nat_gateway" "public_one" {
  provider = aws.one
    count = 2
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_one[count.index].id
  tags = var.tags
}

resource "aws_nat_gateway" "public_two" {
  provider = aws.two
    count = 2
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_two[count.index].id
  tags = var.tags
}

resource "aws_ec2_transit_gateway_route_table" "route_table_one" {
  provider = aws.one
  transit_gateway_id = var.transit_gateway.id
  tags = var.tags
}

# resource "aws_ec2_transit_gateway_route_table" "route_table_two" {
#   provider = aws.two
#   transit_gateway_id = aws_ec2_transit_gateway.example.id
#   # tags               = local.tags
# }

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_one_attachment" {
  provider = aws.one
  subnet_ids                                      = [aws_subnet.public_one[0].id, aws_subnet.public_one[1].id]
  transit_gateway_id                              = var.transit_gateway.id
  vpc_id                                          = aws_vpc.vpc_one.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = var.tags
}

# resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_two_attachment" {
#   provider = aws.two
#   subnet_ids                                      = [aws_subnet.public_one.*.id]
#   transit_gateway_id                              = aws_ec2_transit_gateway.example.id
#   vpc_id                                          = aws_vpc.vpc_one.id
#   transit_gateway_default_route_table_association = false
#   transit_gateway_default_route_table_propagation = false

#   # tags = local.tags
# }

resource "aws_ec2_transit_gateway_route_table_association" "route_one" {
  provider = aws.one
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_one_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table_one.id
}

# resource "aws_ec2_transit_gateway_route_table_association" "route_two" {
#   provider = aws.two
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.example.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
# }

resource "aws_ec2_transit_gateway_route_table_propagation" "route_one" {
  provider = aws.one
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_one_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table_one.id
}

# resource "aws_ec2_transit_gateway_route_table_propagation" "route_two" {
#   provider = aws.two
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.example.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
# }

# resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "accept_external_vpc" {
#   provider = aws.one
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.example.id
#   tags = local.tags
# }

