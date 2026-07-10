locals {
  name_prefix = "${var.project_name}-cwan"
}

data "aws_vpc" "shared" {
  id = var.vpc_id
}

data "aws_subnet" "shared" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

resource "aws_networkmanager_global_network" "this" {
  description = "${local.name_prefix} global network"

  tags = {
    Name = "${local.name_prefix}-global-network"
  }
}

resource "aws_networkmanager_core_network" "this" {
  global_network_id   = aws_networkmanager_global_network.this.id
  description         = "${local.name_prefix} core network"
  create_base_policy  = true
  base_policy_regions = var.edge_locations

  tags = {
    Name = "${local.name_prefix}-core-network"
  }

  lifecycle {
    ignore_changes = [base_policy_regions]
  }
}

data "aws_networkmanager_core_network_policy_document" "this" {
  core_network_configuration {
    asn_ranges = [var.asn_range]

    dynamic "edge_locations" {
      for_each = var.edge_locations
      content {
        location = edge_locations.value
      }
    }
  }

  segments {
    name                          = var.shared_segment_name
    description                   = "Shared services segment"
    require_attachment_acceptance = false
  }

  segments {
    name                          = var.workloads_segment_name
    description                   = "Allowed consumer segment"
    require_attachment_acceptance = false
  }

  segments {
    name                          = var.sandbox_segment_name
    description                   = "Isolated consumer segment"
    require_attachment_acceptance = false
  }

  segment_actions {
    action     = "share"
    mode       = "attachment-route"
    segment    = var.shared_segment_name
    share_with = [var.workloads_segment_name]
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = var.shared_segment_name
    }

    action {
      association_method = "constant"
      segment            = var.shared_segment_name
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = var.workloads_segment_name
    }

    action {
      association_method = "constant"
      segment            = var.workloads_segment_name
    }
  }

  attachment_policies {
    rule_number     = 300
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = var.sandbox_segment_name
    }

    action {
      association_method = "constant"
      segment            = var.sandbox_segment_name
    }
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "this" {
  core_network_id = aws_networkmanager_core_network.this.id
  policy_document = data.aws_networkmanager_core_network_policy_document.this.json
}

resource "aws_networkmanager_vpc_attachment" "shared" {
  core_network_id = aws_networkmanager_core_network.this.id
  vpc_arn         = data.aws_vpc.shared.arn
  subnet_arns     = data.aws_subnet.shared[*].arn


  tags = {
    Name    = "${local.name_prefix}-shared-attachment"
    segment = var.shared_segment_name
  }

  depends_on = [aws_networkmanager_core_network_policy_attachment.this]
}

resource "aws_route" "to_consumers" {
  count = length(var.route_table_ids) * length(var.consumer_vpc_cidrs)

  route_table_id         = var.route_table_ids[floor(count.index / length(var.consumer_vpc_cidrs))]
  destination_cidr_block = var.consumer_vpc_cidrs[count.index % length(var.consumer_vpc_cidrs)]
  core_network_arn       = aws_networkmanager_core_network.this.arn

  depends_on = [aws_networkmanager_vpc_attachment.shared]
}

resource "aws_security_group_rule" "alb_ingress_http" {
  count = length(var.alb_allowed_source_cidrs)

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.alb_allowed_source_cidrs[count.index]]
  security_group_id = var.alb_security_group_id
  description       = "HTTP from ${var.alb_allowed_source_cidrs[count.index]} via Cloud WAN"
}

resource "aws_ram_resource_share" "this" {
  provider = aws.us_east_1

  name                      = "${local.name_prefix}-core-share"
  allow_external_principals = true

  tags = {
    Name = "${local.name_prefix}-core-share"
  }
}

resource "aws_ram_resource_association" "this" {
  provider = aws.us_east_1

  resource_arn       = aws_networkmanager_core_network.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  provider = aws.us_east_1
  count    = length(var.consumer_account_ids)

  principal          = var.consumer_account_ids[count.index]
  resource_share_arn = aws_ram_resource_share.this.arn
}
