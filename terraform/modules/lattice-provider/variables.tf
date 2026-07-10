variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "alb_arn" {
  type        = string
  description = "ARN of the internal ALB"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID"
}

variable "vpc_id" {
  type        = string
  description = "Shared-services VPC ID"
}

variable "consumer_account_ids" {
  type        = list(string)
  description = "Consumer account IDs to share the service network with"
}
