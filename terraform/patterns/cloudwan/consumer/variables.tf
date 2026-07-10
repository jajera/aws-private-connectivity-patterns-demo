variable "aws_region" {
  type        = string
  description = "Workloads consumer AWS Region"
  default     = "ap-southeast-6"
}

variable "sandbox_aws_region" {
  type        = string
  description = "Sandbox consumer AWS Region"
  default     = "ap-southeast-1"
}

variable "ram_region" {
  type        = string
  description = "Region for RAM global resource operations"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-cwan"
}

variable "workloads_vpc_cidr" {
  type        = string
  description = "Workloads consumer VPC CIDR"
  default     = "10.24.0.0/16"
}

variable "sandbox_vpc_cidr" {
  type        = string
  description = "Sandbox consumer VPC CIDR"
  default     = "10.34.0.0/16"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.14.0.0/16"
}

variable "core_network_id" {
  type        = string
  description = "Cloud WAN core network ID from shared-services"
}

variable "core_network_arn" {
  type        = string
  description = "Cloud WAN core network ARN from shared-services"
}

variable "core_network_resource_share_arn" {
  type        = string
  description = "Cloud WAN RAM resource share ARN from shared-services"
}
