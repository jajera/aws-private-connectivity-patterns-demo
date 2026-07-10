locals {
  name_prefix = "${var.project_name}-tgw"
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = "${local.name_prefix} demo transit gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = local.name_prefix
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared_services" {
  subnet_ids                                      = var.subnet_ids
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = var.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${local.name_prefix}-shared-services-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${local.name_prefix}-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "shared_services" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route" "shared_services_cidr" {
  destination_cidr_block         = var.shared_services_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
}

resource "aws_ec2_transit_gateway_route" "consumer_cidr" {
  count = var.consumer_tgw_attachment_id != "" ? 1 : 0

  destination_cidr_block         = var.consumer_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id  = var.consumer_tgw_attachment_id
}

resource "aws_ec2_transit_gateway_route_table_association" "consumer" {
  count = var.consumer_tgw_attachment_id != "" ? 1 : 0

  transit_gateway_attachment_id  = var.consumer_tgw_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_route" "to_consumer" {
  count = var.consumer_vpc_cidr != "" ? length(var.route_table_ids) : 0

  route_table_id         = var.route_table_ids[count.index]
  destination_cidr_block = var.consumer_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_ram_resource_share" "this" {
  name                      = "${local.name_prefix}-share"
  allow_external_principals = true

  tags = {
    Name = "${local.name_prefix}-share"
  }
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  count = length(var.consumer_account_ids)

  principal          = var.consumer_account_ids[count.index]
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_security_group_rule" "alb_ingress_http" {
  count = var.consumer_vpc_cidr != "" ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.consumer_vpc_cidr]
  security_group_id = var.alb_security_group_id
  description       = "HTTP from consumer VPC via TGW"
}
