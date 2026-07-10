output "vpc_id" {
  description = "Consumer VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Consumer VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}

output "test_ec2_instance_id" {
  description = "Test EC2 instance ID for SSM"
  value       = module.test_ec2.instance_id
}

output "peering_connection_id" {
  description = "VPC peering connection ID"
  value       = module.peering.peering_connection_id
}
