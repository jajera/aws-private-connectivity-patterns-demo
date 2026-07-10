variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tags"
  default     = "apcp-tgw"
}

variable "vpc_cidr" {
  type        = string
  description = "Shared-services VPC CIDR"
  default     = "10.13.0.0/16"
}

variable "consumer_account_id" {
  type        = string
  description = "Consumer (dev) AWS account ID"
}

variable "consumer_vpc_cidr" {
  type        = string
  description = "Consumer VPC CIDR"
  default     = "10.23.0.0/16"
}

variable "consumer_tgw_attachment_id" {
  type        = string
  description = "Consumer TGW attachment ID from consumer (third apply). Leave empty until consumer attaches."
  default     = ""
}
