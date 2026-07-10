variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB and EC2 placement"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ALB (minimum 2 AZs)"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR for baseline security group rules"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "apcp"
}

variable "connectivity_pattern" {
  type        = string
  description = "Value returned in the JSON pattern field"
  default     = "shared-services"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}
