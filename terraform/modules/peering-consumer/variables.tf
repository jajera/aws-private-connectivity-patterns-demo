variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Consumer private route table IDs"
}

variable "shared_services_vpc_id" {
  type        = string
  description = "Shared services VPC ID to peer with"
}

variable "shared_services_account_id" {
  type        = string
  description = "Shared services AWS account ID"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared services VPC CIDR"
}

variable "test_ec2_sg_id" {
  type        = string
  description = "Test EC2 security group ID"
}

variable "enable_requester_dns" {
  type        = bool
  description = "Enable requester DNS resolution. Set true only after shared-services has accepted the peering."
  default     = false
}
