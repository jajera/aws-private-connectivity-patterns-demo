variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "Shared-services VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for TGW VPC attachment"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Shared-services private route table IDs"
}

variable "consumer_account_ids" {
  type        = list(string)
  description = "Consumer account IDs to share the TGW with"
}

variable "consumer_vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR (required for VPC routes and ALB SG)"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
}

variable "consumer_tgw_attachment_id" {
  type        = string
  description = "Consumer TGW VPC attachment ID from consumer stack (second shared-services apply)"
  default     = ""
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID"
}
