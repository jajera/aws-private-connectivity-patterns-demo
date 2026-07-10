resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.vpc_id
  peer_vpc_id   = var.shared_services_vpc_id
  peer_owner_id = var.shared_services_account_id
  auto_accept   = false

  tags = {
    Name = "${var.project_name}-peering"
  }
}

# Only after shared-services has accepted (peering status = active).
resource "aws_vpc_peering_connection_options" "requester" {
  count = var.enable_requester_dns ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "to_shared_services" {
  count = length(var.route_table_ids)

  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = var.shared_services_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_security_group_rule" "test_ec2_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.shared_services_vpc_cidr]
  security_group_id = var.test_ec2_sg_id
  description       = "HTTP to shared services VPC via peering"
}
