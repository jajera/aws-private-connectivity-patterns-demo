variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "peering_connection_id" {
  type        = string
  description = "VPC peering connection ID from the consumer stack"
}

variable "consumer_vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Shared-services private route table IDs"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID"
}
