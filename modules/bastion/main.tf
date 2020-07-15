# ---------------------------------------------------------------------------------------------------------------------
# BASTION
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "this" {
  byte_length = 1
}

resource "aws_eip" "this" {
  vpc      = true
  instance = aws_instance.this.id
  tags = {
    Name      = "Elastic IP for SSH"
    Terraform = "true"
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  tags = {
    Name = join("-", [var.name, random_id.this.hex])
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-${random_id.this.hex}"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = var.name
    Module = path.module
  }

  lifecycle {
    create_before_destroy = true
  }
}