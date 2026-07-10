output "alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}
