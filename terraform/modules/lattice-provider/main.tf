locals {
  name_prefix = "${var.project_name}-lat"
}

resource "aws_vpclattice_service" "this" {
  name      = "${local.name_prefix}-service"
  auth_type = "NONE"

  tags = {
    Name = "${local.name_prefix}-service"
  }
}

resource "aws_vpclattice_target_group" "this" {
  name = "${local.name_prefix}-tg"
  type = "ALB"

  config {
    port           = 80
    protocol       = "HTTP"
    vpc_identifier = var.vpc_id
  }
}

resource "aws_vpclattice_target_group_attachment" "alb" {
  target_group_identifier = aws_vpclattice_target_group.this.arn
  target {
    id   = var.alb_arn
    port = 80
  }
}

data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  name = "com.amazonaws.${var.aws_region}.vpc-lattice"
}

resource "aws_security_group_rule" "alb_ingress_lattice" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.vpc_lattice.id]
  security_group_id = var.alb_security_group_id
  description       = "HTTP from VPC Lattice to ALB"
}

resource "aws_vpclattice_listener" "this" {
  name               = "${local.name_prefix}-listener"
  protocol           = "HTTP"
  port               = 80
  service_identifier = aws_vpclattice_service.this.arn

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.this.arn
        weight                  = 100
      }
    }
  }

  depends_on = [aws_vpclattice_target_group_attachment.alb]
}

resource "aws_vpclattice_service_network" "this" {
  name = "${local.name_prefix}-network"

  tags = {
    Name = "${local.name_prefix}-network"
  }
}

resource "aws_vpclattice_service_network_service_association" "this" {
  service_network_identifier = aws_vpclattice_service_network.this.arn
  service_identifier         = aws_vpclattice_service.this.arn
}

resource "aws_ram_resource_share" "this" {
  name                      = "${local.name_prefix}-share"
  allow_external_principals = true

  tags = {
    Name = "${local.name_prefix}-share"
  }
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_vpclattice_service_network.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  count = length(var.consumer_account_ids)

  principal          = var.consumer_account_ids[count.index]
  resource_share_arn = aws_ram_resource_share.this.arn
}
