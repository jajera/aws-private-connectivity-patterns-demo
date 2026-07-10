variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "endpoint_service_name" {
  type        = string
  description = "VPC endpoint service name from shared-services"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the interface endpoint"
}

variable "test_ec2_sg_id" {
  type        = string
  description = "Test EC2 security group ID"
}
