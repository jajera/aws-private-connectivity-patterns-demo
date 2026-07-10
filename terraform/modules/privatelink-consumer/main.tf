locals {
  name_prefix = "${var.project_name}-pl"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "endpoint" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "Security group for PrivateLink interface endpoint"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-vpce-sg"
  }
}

resource "aws_security_group_rule" "endpoint_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.endpoint.id
  description       = "HTTP from consumer VPC to interface endpoint"
}

resource "aws_security_group_rule" "endpoint_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.endpoint.id
  description       = "HTTP to endpoint service"
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = var.endpoint_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false

  tags = {
    Name = "${local.name_prefix}-vpce"
  }
}

resource "aws_security_group_rule" "test_ec2_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.test_ec2_sg_id
  description       = "HTTP to PrivateLink endpoint"
}
