output "account_id" {
  description = "Shared-services AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  description = "Shared-services VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Shared-services VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}

output "alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = module.app.alb_dns_name
}

output "lattice_service_network_arn" {
  description = "Lattice service network ARN"
  value       = module.lattice.lattice_service_network_arn
}

output "lattice_resource_share_arn" {
  description = "RAM resource share ARN"
  value       = module.lattice.resource_share_arn
}

output "lattice_service_dns_name" {
  description = "Lattice service DNS name for curl"
  value       = module.lattice.lattice_service_dns_name
}
