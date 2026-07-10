output "endpoint_service_name" {
  description = "VPC endpoint service name"
  value       = aws_vpc_endpoint_service.this.service_name
}
