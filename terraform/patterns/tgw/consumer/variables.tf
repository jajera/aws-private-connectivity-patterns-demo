variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-tgw"
}

variable "vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR"
  default     = "10.23.0.0/16"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.13.0.0/16"
}

variable "tgw_id" {
  type        = string
  description = "Transit Gateway ID from shared-services"
}

variable "tgw_resource_share_arn" {
  type        = string
  description = "RAM resource share ARN from shared-services"
}
