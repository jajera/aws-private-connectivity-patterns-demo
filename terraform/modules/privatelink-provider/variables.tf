variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "nlb_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for NLB placement"
}

variable "alb_arn" {
  type        = string
  description = "ARN of the internal ALB"
}

variable "alb_listener_arn" {
  type        = string
  description = "ARN of the internal ALB listener (used to enforce creation order)"
}

variable "vpc_id" {
  type        = string
  description = "Shared-services VPC ID"
}

variable "allowed_principals" {
  type        = list(string)
  description = "IAM principals allowed to create endpoints"
}
