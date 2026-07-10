variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "tgw_id" {
  type        = string
  description = "Shared Transit Gateway ID"
}

variable "resource_share_arn" {
  type        = string
  description = "RAM resource share ARN"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Consumer subnet IDs for TGW attachment"
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
