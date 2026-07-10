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

output "global_network_id" {
  description = "Cloud WAN global network ID"
  value       = module.cloudwan.global_network_id
}

output "core_network_id" {
  description = "Cloud WAN core network ID"
  value       = module.cloudwan.core_network_id
}

output "core_network_arn" {
  description = "Cloud WAN core network ARN"
  value       = module.cloudwan.core_network_arn
}

output "core_network_resource_share_arn" {
  description = "Cloud WAN core network RAM share ARN"
  value       = module.cloudwan.resource_share_arn
}
