# ---------------------------------------------------------------------------------------------------------------------
# WEBSERVER
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "this" {
  byte_length = 1
}

# ----------- AUTOSCALING GROUP

resource "aws_autoscaling_group" "this" {
  default_cooldown          = 60
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.this.id
  min_size                  = 1
  max_size                  = 5
  name                      = "autoscaling-${var.name}-${random_id.this.hex}"
  vpc_zone_identifier       = var.vpc_subnets_priv

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

# ----------- SECURITY GROUP

resource "aws_security_group" "this" {
  name        = "securitygroup-webserver-${var.name}-${random_id.this.hex}"
  description = "Allow traffic on TCP 80 (HTTP) TCP 443 (HTTPS) and SSH from local network"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
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
    Name   = "securitygroup-webserver-${var.name}-${random_id.this.hex}"
    Module = path.module
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ----------- IAM

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

# ----------- LOAD BALANCING

resource "aws_lb" "this" {
  name               = "lb-${var.name}-${random_id.this.hex}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.vpc_subnets_pub
  security_groups    = [aws_security_group.this.id]
}

resource "aws_lb_target_group" "this" {
  name     = "lb-tg-${var.name}-${random_id.this.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = var.http_port
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_attachment" "this" {
  alb_target_group_arn   = aws_lb_target_group.this.arn
  autoscaling_group_name = aws_autoscaling_group.this.id
}
