locals {
  name_prefix = "${var.project_name}-tgw"
}

resource "terraform_data" "accept_ram_share" {
  input = var.resource_share_arn

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      INVITATION=$(aws ram get-resource-share-invitations \
        --region "${var.aws_region}" \
        --resource-share-arns "${var.resource_share_arn}" \
        --query "resourceShareInvitations[?status=='PENDING'].resourceShareInvitationArn | [0]" \
        --output text)
      if [ -n "$${INVITATION}" ] && [ "$${INVITATION}" != "None" ] && [ "$${INVITATION}" != "null" ]; then
        aws ram accept-resource-share-invitation \
          --region "${var.aws_region}" \
          --resource-share-invitation-arn "$${INVITATION}"
      fi
    EOT
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids                                      = var.subnet_ids
  transit_gateway_id                              = var.tgw_id
  vpc_id                                          = var.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${local.name_prefix}-consumer-attachment"
  }

  depends_on = [terraform_data.accept_ram_share]
}

resource "aws_route" "to_shared_services" {
  count = length(var.route_table_ids)

  route_table_id         = var.route_table_ids[count.index]
  destination_cidr_block = var.shared_services_vpc_cidr
  transit_gateway_id     = var.tgw_id
}

resource "aws_security_group_rule" "test_ec2_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.shared_services_vpc_cidr]
  security_group_id = var.test_ec2_sg_id
  description       = "HTTP to shared services VPC via TGW"
}
