output "lattice_service_dns_name" {
  description = "VPC Lattice service DNS name"
  value = try(
    [for entry in aws_vpclattice_service.this.dns_entry : entry.domain_name if entry.domain_name != ""][0],
    null
  )
}

output "lattice_service_network_arn" {
  description = "VPC Lattice service network ARN"
  value       = aws_vpclattice_service_network.this.arn
}

output "resource_share_arn" {
  description = "RAM resource share ARN for the service network"
  value       = aws_ram_resource_share.this.arn
}
