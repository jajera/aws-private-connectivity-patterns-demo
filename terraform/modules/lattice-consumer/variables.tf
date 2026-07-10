variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "service_network_arn" {
  type        = string
  description = "ARN of the shared Lattice service network"
}

variable "resource_share_arn" {
  type        = string
  description = "RAM resource share ARN"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}
