# ---------------------------------------------------------------------------------------------------------------------
# WEBSERVER
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "this" {
  byte_length = 1
}

resource "aws_autoscaling_group" "this" {
  default_cooldown          = 60
  desired_capacity          = 3
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.this.id
  min_size                  = 1
  max_size                  = 5
  name                      = "autoscaling-${var.name}-${random_id.this.hex}"
  vpc_zone_identifier       = var.vpc_subnets

  tags = [
    {
      key                 = "Name"
      value               = "instance-${var.name}-${random_id.this.hex}"
      propagate_at_launch = true
    },
    {
      key                 = "Workspace"
      value               = terraform.workspace
      propagate_at_launch = true
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "this" {
  enable_monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.this.name
  image_id             = data.aws_ami.this.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  name_prefix          = "livestream-lc-"
  security_groups      = [aws_security_group.this.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  name        = "livestream-sg-http"
  description = "Allow traffic on TCP 80 (HTTP) TCP 443 (HTTPS)"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "sg-${var.name}-${random_id.this.hex}"
    Module = path.module
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-${random_id.this.hex}"
  path = "/"
  role = aws_iam_role.this.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "${var.name}-${random_id.this.hex}"
  path               = "/"

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-${random_id.this.hex}"
  policy = data.aws_iam_policy_document.role_policy.json
  role   = aws_iam_role.this.id

  lifecycle {
    create_before_destroy = true
  }
}