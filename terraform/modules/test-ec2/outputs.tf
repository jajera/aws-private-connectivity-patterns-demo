output "instance_id" {
  description = "EC2 instance ID used for SSM session"
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "Test EC2 security group ID for lab SG rules"
  value       = aws_security_group.this.id
}
