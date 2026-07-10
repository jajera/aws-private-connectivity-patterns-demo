output "vpc_attachment_id" {
  description = "Cloud WAN VPC attachment ID"
  value       = aws_networkmanager_vpc_attachment.this.id
}

output "segment_name" {
  description = "Segment selected for this attachment"
  value       = aws_networkmanager_vpc_attachment.this.segment_name
}
