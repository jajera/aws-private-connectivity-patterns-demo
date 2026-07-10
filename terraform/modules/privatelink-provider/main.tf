locals {
  name_prefix = "${var.project_name}-pl"
}

resource "aws_lb" "nlb" {
  name               = "${local.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.nlb_subnet_ids

  tags = {
    Name = "${local.name_prefix}-nlb"
  }
}

resource "aws_lb_target_group" "nlb" {
  name        = "${local.name_prefix}-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "${local.name_prefix}-nlb-tg"
  }
}

resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.nlb.arn
  target_id        = var.alb_arn
  port             = 80
  depends_on       = [terraform_data.alb_listener_ready]
}

resource "terraform_data" "alb_listener_ready" {
  input = var.alb_listener_arn
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb.arn
  }
}

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
  allowed_principals         = var.allowed_principals

  tags = {
    Name = "${local.name_prefix}-endpoint-service"
  }
}
