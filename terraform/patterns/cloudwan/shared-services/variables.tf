variable "aws_region" {
  type        = string
  description = "Shared-services AWS Region"
  default     = "ap-southeast-2"
}

variable "ram_region" {
  type        = string
  description = "Region for RAM global resource sharing"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-cwan"
}

variable "vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.14.0.0/16"
}

variable "consumer_account_id" {
  type        = string
  description = "Consumer (dev) AWS account ID"
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

variable "edge_locations" {
  type        = list(string)
  description = "Cloud WAN edge locations"
  default     = ["ap-southeast-2", "ap-southeast-6", "ap-southeast-1"]
}
