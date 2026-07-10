locals {
  name_prefix = "${var.project_name}-${var.account_name}-test"
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

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for test EC2"
  vpc_id      = var.vpc_id

  # No inline rules — lab modules may attach aws_security_group_rule resources.

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all egress"
}

resource "aws_iam_role" "this" {
  name = "${local.name_prefix}-role"

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
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-profile"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023_x86.id
  instance_type               = "t3.nano"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = concat([aws_security_group.this.id], var.security_group_ids)
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false
  user_data                   = <<-EOF
    #!/bin/bash
    set -euo pipefail
    dnf install -y amazon-ssm-agent || true
    systemctl enable amazon-ssm-agent
    systemctl restart amazon-ssm-agent
  EOF

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}
