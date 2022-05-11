terraform {
  required_version = ">=0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.shared, aws.child_account ]
    }
  }
}

data "aws_availability_zones" "available" {
  provider = aws.child_account
  state = "available"
}

resource "aws_vpc" "vpc" {
  provider = aws.child_account
  cidr_block = var.vpc_cidr
  tags = merge(
    var.tags,
    {
      Name = "3Tgw-VPC"
    },
  )
}

resource "aws_internet_gateway" "igw" {
  provider = aws.child_account
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.tags,
    {
      Name = "3Tgw-IGW"
    },
  )
}

resource "aws_subnet" "public" {
    provider = aws.child_account
    count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw public", count.index+1])
    },
  )
}

resource "aws_subnet" "private" {
    provider = aws.child_account
    count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+2)
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw private", count.index+1])
    },
  )
}

resource "aws_network_acl" "private" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+2)
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+2)
    from_port  = 80
    to_port    = 80
  }

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw private NACL", count.index+1])
    },
  )
}

resource "aws_network_acl_association" "private" {
  provider = aws.child_account
  count = 2
  network_acl_id = aws_network_acl.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_subnet" "data" {
    provider = aws.child_account
    count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+4)
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw data", count.index+1])
    },
  )
}

resource "aws_network_acl" "data" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+4)
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+4)
    from_port  = 80
    to_port    = 80
  }

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw data NACL", count.index+1])
    },
  )
}

resource "aws_network_acl_association" "data" {
  provider = aws.child_account
  count = 2
  network_acl_id = aws_network_acl.data[count.index].id
  subnet_id      = aws_subnet.data[count.index].id
}

resource "aws_subnet" "intranet" {
    provider = aws.child_account
    count = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+6)
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw intranet", count.index+1])
    },
  )
}

resource "aws_network_acl" "intranet" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+6)
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+6)
    from_port  = 80
    to_port    = 80
  }

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw intranet NACL", count.index+1])
    },
  )
}

resource "aws_network_acl_association" "intranet" {
  provider = aws.child_account
  count = 2
  network_acl_id = aws_network_acl.intranet[count.index].id
  subnet_id      = aws_subnet.intranet[count.index].id
}

resource "aws_eip" "nat_ip" {
  provider = aws.child_account
  count = 2
  vpc      = true
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw EIP", count.index+1])
    },
  )
}

resource "aws_nat_gateway" "public" {
  count = 2
  provider = aws.child_account
  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id         = aws_subnet.public[count.index].id
  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw NAT", count.index+1])
    },
  )
}

resource "aws_route_table" "public" {
  provider = aws.child_account
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "3Tgw public route table"
    },
  )
}

resource "aws_route_table_association" "public" {
  provider = aws.child_account
  count = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw private route table", count.index+1])
    },
  )
}

resource "aws_route_table_association" "private" {
  provider = aws.child_account
  count = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "data" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id
  route = []

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw data route table", count.index+1])
    },
  )
}

resource "aws_route_table_association" "data" {
  provider = aws.child_account
  count = 2
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data[count.index].id
}

resource "aws_route_table" "intranet" {
  provider = aws.child_account
  count = 2
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.tags,
    {
      Name = join(" ", ["3Tgw intranet route table", count.index+1])
    },
  )
}

resource "aws_route_table_association" "intranet" {
  provider = aws.child_account
  count = 2
  subnet_id      = aws_subnet.intranet[count.index].id
  route_table_id = aws_route_table.intranet[count.index].id
}

resource "aws_ec2_transit_gateway_route_table" "route_table" {
  provider = aws.shared
  transit_gateway_id = var.transit_gateway
  tags = merge(
    var.tags,
    {
      Name = "3Tgw-tgw-route-table"
    },
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  # count = 2
  provider = aws.child_account
  subnet_ids                                      = [aws_subnet.intranet[0].id, aws_subnet.intranet[1].id]
  transit_gateway_id                              = var.transit_gateway
  vpc_id                                          = aws_vpc.vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(
    var.tags,
    {
      Name = "3Tgw-vpc-attachment"
    },
  )
}

# resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "accept_external_vpc" {
#   count = 2
#   provider = aws.shared
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment[count.index].id
#   transit_gateway_default_route_table_association = false
#   transit_gateway_default_route_table_propagation = false
#   tags = merge(
#     var.tags,
#     {
#       Name = "3Tgw-vpc-attachment-accepter"
#     },
#   )
# }

resource "aws_ec2_transit_gateway_route_table_association" "route" {
  # count = 2
  provider = aws.child_account
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "route" {
  # count = 2
  provider = aws.child_account
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table.id
}


# resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "accept_external_vpc_2" {
#   count = var.same_as_shared_account ? 0 : 1
#   provider = aws.shared
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment[1].id
#   tags = merge(
#     var.tags,
#     {
#       Name = "3Tgw-vpc-attachment-accepter"
#     },
#   )
# }

