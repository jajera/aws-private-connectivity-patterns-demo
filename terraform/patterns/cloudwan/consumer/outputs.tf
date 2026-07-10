output "workloads_vpc_id" {
  description = "Workloads consumer VPC ID"
  value       = module.vpc_workloads.vpc_id
}

output "sandbox_vpc_id" {
  description = "Sandbox consumer VPC ID"
  value       = module.vpc_sandbox.vpc_id
}

output "workloads_test_ec2_instance_id" {
  description = "Workloads test EC2 instance ID for SSM"
  value       = module.test_ec2_workloads.instance_id
}

output "sandbox_test_ec2_instance_id" {
  description = "Sandbox test EC2 instance ID for SSM"
  value       = module.test_ec2_sandbox.instance_id
}

output "workloads_attachment_id" {
  description = "Cloud WAN workloads attachment ID"
  value       = module.cloudwan_workloads.vpc_attachment_id
}

output "sandbox_attachment_id" {
  description = "Cloud WAN sandbox attachment ID"
  value       = module.cloudwan_sandbox.vpc_attachment_id
}
