locals {
  name_prefix = "${var.project_name}-cwan"
}

data "aws_vpc" "consumer" {
  id = var.vpc_id
}

data "aws_subnet" "consumer" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

resource "terraform_data" "accept_ram_share" {
  count = var.accept_ram_share ? 1 : 0

  input = var.resource_share_arn

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      INVITATION=$(aws ram get-resource-share-invitations \
        --region "${var.ram_region}" \
        --resource-share-arns "${var.resource_share_arn}" \
        --query "resourceShareInvitations[?status=='PENDING'].resourceShareInvitationArn | [0]" \
        --output text)
      if [ -n "$${INVITATION}" ] && [ "$${INVITATION}" != "None" ] && [ "$${INVITATION}" != "null" ]; then
        aws ram accept-resource-share-invitation \
          --region "${var.ram_region}" \
          --resource-share-invitation-arn "$${INVITATION}"
      fi
    EOT
  }
}

resource "aws_networkmanager_vpc_attachment" "this" {
  core_network_id = var.core_network_id
  vpc_arn         = data.aws_vpc.consumer.arn
  subnet_arns     = data.aws_subnet.consumer[*].arn


  tags = {
    Name    = "${local.name_prefix}-${var.segment_name}-attachment"
    segment = var.segment_name
  }

  depends_on = [terraform_data.accept_ram_share]
}

resource "aws_route" "to_shared_services" {
  count = length(var.route_table_ids)

  route_table_id         = var.route_table_ids[count.index]
  destination_cidr_block = var.shared_services_vpc_cidr
  core_network_arn       = var.core_network_arn

  depends_on = [aws_networkmanager_vpc_attachment.this]
}

resource "aws_security_group_rule" "test_ec2_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.shared_services_vpc_cidr]
  security_group_id = var.test_ec2_sg_id
  description       = "HTTP to shared services VPC via Cloud WAN"
}
