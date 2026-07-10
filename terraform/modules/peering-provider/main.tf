resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = var.peering_connection_id
  auto_accept               = true

  tags = {
    Name = "${var.project_name}-peering-accepter"
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "to_consumer" {
  count = length(var.route_table_ids)

  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = var.consumer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.consumer_vpc_cidr]
  security_group_id = var.alb_security_group_id
  description       = "HTTP from consumer VPC via peering"
}
