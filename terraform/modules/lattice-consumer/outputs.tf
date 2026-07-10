output "vpc_association_id" {
  description = "Lattice service network VPC association ID"
  value       = aws_vpclattice_service_network_vpc_association.this.id
}
