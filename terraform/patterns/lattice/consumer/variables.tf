variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-lat"
}

variable "vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR"
  default     = "10.22.0.0/16"
}

variable "shared_services_vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.12.0.0/16"
}

variable "lattice_service_network_arn" {
  type        = string
  description = "Lattice service network ARN from shared-services"
}

variable "lattice_resource_share_arn" {
  type        = string
  description = "RAM resource share ARN from shared-services"
}
