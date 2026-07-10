variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "core_network_id" {
  type        = string
  description = "Cloud WAN core network ID"
}

variable "core_network_arn" {
  type        = string
  description = "Cloud WAN core network ARN"
}

variable "resource_share_arn" {
  type        = string
  description = "RAM resource share ARN"
}

variable "ram_region" {
  type        = string
  description = "Region used for RAM operations"
  default     = "us-east-1"
}

variable "accept_ram_share" {
  type        = bool
  description = "Whether this module should accept RAM share invitation"
  default     = false
}

variable "segment_name" {
  type        = string
  description = "Cloud WAN segment tag value for this attachment"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Consumer subnet IDs for Cloud WAN attachment"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Consumer private route table IDs"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
}

variable "test_ec2_sg_id" {
  type        = string
  description = "Test EC2 security group ID"
}
