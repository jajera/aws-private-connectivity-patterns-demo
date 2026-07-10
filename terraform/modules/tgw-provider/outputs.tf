output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "resource_share_arn" {
  description = "RAM resource share ARN for the Transit Gateway"
  value       = aws_ram_resource_share.this.arn
}

output "shared_services_attachment_id" {
  description = "Shared-services TGW VPC attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
}
