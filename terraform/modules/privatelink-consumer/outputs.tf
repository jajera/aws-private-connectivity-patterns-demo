output "vpc_endpoint_id" {
  description = "Interface VPC endpoint ID"
  value       = aws_vpc_endpoint.this.id
}

output "endpoint_dns_name" {
  description = "DNS name for curl tests"
  value = try(
    [for entry in aws_vpc_endpoint.this.dns_entry : entry.dns_name if entry.dns_name != ""][0],
    null
  )
}
