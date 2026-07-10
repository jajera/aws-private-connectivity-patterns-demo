locals {
  # Keep short: ALB/TG names are limited to 32 chars; IAM role names to 64.
  name_prefix = "${var.project_name}-ss-app"
}

data "aws_ami" "al2023_x86" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  # No inline rules — labs add aws_security_group_rule resources to this SG.
  # Mixing inline rules with standalone rules causes perpetual drift.

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_ingress_vpc_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from VPC"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all egress"
}

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2"
  description = "Security group for shared services app EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

resource "aws_security_group_rule" "ec2_ingress_alb_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2.id
  description              = "HTTP from ALB"
}

resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all egress"
}

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${local.name_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023_x86.id
  instance_type          = "t3.nano"
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # AL2023 already includes python3. Avoid package install during boot for reliability.
  user_data_replace_on_change = true
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    cat >/opt/shared-services-app.py <<'PY'
    import json
    import socket
    import urllib.request
    from datetime import datetime, timezone
    from http.server import BaseHTTPRequestHandler, HTTPServer

    PATTERN = "${var.connectivity_pattern}"

    def instance_id():
        try:
            token_req = urllib.request.Request(
                "http://169.254.169.254/latest/api/token",
                method="PUT",
                headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
            )
            token = urllib.request.urlopen(token_req, timeout=2).read().decode()
            id_req = urllib.request.Request(
                "http://169.254.169.254/latest/meta-data/instance-id",
                headers={"X-aws-ec2-metadata-token": token},
            )
            return urllib.request.urlopen(id_req, timeout=2).read().decode()
        except Exception:
            return "unknown"

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            body = json.dumps({
                "pattern": PATTERN,
                "hostname": socket.gethostname(),
                "instance_id": instance_id(),
                "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            }).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, format, *args):
            return

    if __name__ == "__main__":
        HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
    PY

    cat >/etc/systemd/system/shared-services-app.service <<'UNIT'
    [Unit]
    Description=Shared services demo HTTP API
    After=network-online.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/shared-services-app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now shared-services-app.service
  EOF
  )

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.app.id
  port             = 80
}
