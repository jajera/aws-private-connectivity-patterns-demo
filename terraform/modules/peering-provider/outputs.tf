output "peering_connection_id" {
  description = "Accepted VPC peering connection ID"
  value       = aws_vpc_peering_connection_accepter.this.id
}
