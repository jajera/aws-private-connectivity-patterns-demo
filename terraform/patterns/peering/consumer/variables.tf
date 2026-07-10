variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-peer"
}

variable "vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR"
  default     = "10.20.0.0/16"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.10.0.0/16"
}

variable "shared_services_account_id" {
  type        = string
  description = "Shared-services AWS account ID"
}

variable "shared_services_vpc_id" {
  type        = string
  description = "Shared-services VPC ID"
}

variable "enable_requester_dns" {
  type        = bool
  description = "Enable requester DNS after peering is accepted (third apply)"
  default     = false
}
