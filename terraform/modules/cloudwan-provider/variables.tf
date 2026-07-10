variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "Shared-services VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Shared-services private subnet IDs for Cloud WAN attachment"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Shared-services private route table IDs"
}

variable "consumer_account_ids" {
  type        = list(string)
  description = "Consumer account IDs to share the core network with"
}

variable "consumer_vpc_cidrs" {
  type        = list(string)
  description = "Consumer VPC CIDRs routed from shared-services"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID from shared-services app"
}

variable "alb_allowed_source_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access ALB over HTTP"
}

variable "edge_locations" {
  type        = list(string)
  description = "Cloud WAN edge Regions"
}

variable "shared_segment_name" {
  type        = string
  description = "Segment name for shared-services attachments"
  default     = "shared"
}

variable "workloads_segment_name" {
  type        = string
  description = "Segment name for allowed workload attachments"
  default     = "workloads"
}

variable "sandbox_segment_name" {
  type        = string
  description = "Segment name for isolated sandbox attachments"
  default     = "sandbox"
}

variable "asn_range" {
  type        = string
  description = "ASN range used for Cloud WAN core network edges"
  default     = "64512-65534"
}
