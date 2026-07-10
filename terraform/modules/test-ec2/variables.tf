variable "vpc_id" {
  type        = string
  description = "VPC ID for security group"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2 placement"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "apcp"
}

variable "account_name" {
  type        = string
  description = "Account identifier for naming"
  default     = "consumer"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs to attach"
  default     = []
}
