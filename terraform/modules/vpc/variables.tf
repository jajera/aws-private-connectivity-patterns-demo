variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "account_name" {
  type        = string
  description = "Account identifier (shared-services, dev, or sandbox)"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones for private subnets"
  default     = []

  validation {
    condition     = length(var.azs) == 0 || length(var.azs) >= 2
    error_message = "Provide at least two AZs when overriding azs."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for VPC endpoint service names"
  default     = "ap-southeast-2"
}
