output "transit_gateway_arn" {
    value = aws_ec2_transit_gateway.tgw.arn

}
output "transit_gateway_id" {
    value = aws_ec2_transit_gateway.tgw.id
}