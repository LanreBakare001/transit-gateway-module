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

resource "aws_ram_resource_share" "ram" {
  provider = aws.shared
  name = var.ram_name
  allow_external_principals = true
  tags = merge(
    var.tags,
    {
      Name = "3Tgw-RAM"
    },
  )
}



# Share the transit gateway...
resource "aws_ram_resource_association" "ram_resources" {
  count = length(var.tgws)
  provider = aws.shared
  resource_arn       = var.tgws[count.index]
  resource_share_arn = aws_ram_resource_share.ram.id
}

# Share with the second account.
# resource "aws_ram_principal_association" "ram_principal" {
#   count = length(var.ram_principals)
#   provider = aws.shared
#   principal          = var.ram_principals[count.index]
#   resource_share_arn = aws_ram_resource_share.ram.id
# }

# resource "aws_ram_resource_share_accepter" "ram_resources" {
#   count = length(var.ram_principals)
#   provider = aws.child_account
#   share_arn = aws_ram_principal_association.ram_principal[count.index].resource_share_arn
#   depends_on = [
#     aws_ram_principal_association.ram_principal
#   ]
# }