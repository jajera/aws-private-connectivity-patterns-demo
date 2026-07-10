output "global_network_id" {
  description = "Cloud WAN global network ID"
  value       = aws_networkmanager_global_network.this.id
}

output "core_network_id" {
  description = "Cloud WAN core network ID"
  value       = aws_networkmanager_core_network.this.id
}

output "core_network_arn" {
  description = "Cloud WAN core network ARN"
  value       = aws_networkmanager_core_network.this.arn
}

output "resource_share_arn" {
  description = "RAM resource share ARN for the core network"
  value       = aws_ram_resource_share.this.arn
}

output "shared_vpc_attachment_id" {
  description = "Cloud WAN VPC attachment ID for shared-services"
  value       = aws_networkmanager_vpc_attachment.shared.id
}
