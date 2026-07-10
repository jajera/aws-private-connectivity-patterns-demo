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

output "tgw_id" {
  description = "Transit Gateway ID"
  value       = module.tgw.tgw_id
}

output "tgw_resource_share_arn" {
  description = "RAM resource share ARN"
  value       = module.tgw.resource_share_arn
}
