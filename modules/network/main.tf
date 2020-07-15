# ---------------------------------------------------------------------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------------------------------------------------------------------

# ----------- VPC 

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name      = "livestream VPC"
    Terraform = "true"
    Env       = var.env
  }
}

# ----------- SUBNETS

resource "aws_subnet" "pub1" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 2, 0)
  availability_zone = var.az_a
  vpc_id            = aws_vpc.this.id
  tags = {
    Name      = "Public subnet"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_subnet" "priv1" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 2, 1)
  availability_zone = var.az_a
  vpc_id            = aws_vpc.this.id
  tags = {
    Name      = "Private subnet"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_subnet" "pub2" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 2, 2)
  availability_zone = var.az_b
  vpc_id            = aws_vpc.this.id
  tags = {
    Name      = "Public subnet"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_subnet" "priv2" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 2, 3)
  availability_zone = var.az_b
  vpc_id            = aws_vpc.this.id
  tags = {
    Name      = "Private subnet"
    Terraform = "true"
    Env       = var.env
  }
}

# ----------- INTERNET GATEWAY

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name      = "Internet Gateway"
    Terraform = "true"
    Env       = var.env
  }
}

# ----------- ELASTIC IP FOR NATGW

resource "aws_eip" "this_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name      = "Elastic IP for NatGW on AZ ${var.az_a}"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_eip" "this_2" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name      = "Elastic IP for NatGW on AZ ${var.az_b}"
    Terraform = "true"
    Env       = var.env
  }
}

# ----------- NATGATEWAY

resource "aws_nat_gateway" "this_1" {
  allocation_id = aws_eip.this_1.id
  subnet_id     = aws_subnet.pub1.id
  depends_on    = [aws_internet_gateway.this]
  tags = {
    Name      = "Nat gateway AZ1"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_nat_gateway" "this_2" {
  allocation_id = aws_eip.this_2.id
  subnet_id     = aws_subnet.pub2.id
  depends_on    = [aws_internet_gateway.this]
  tags = {
    Name      = "Nat gateway AZ2"
    Terraform = "true"
    Env       = var.env
  }
}

# ----------- ROUTING

resource "aws_route" "livestream_route" {
  route_table_id         = aws_vpc.this.default_route_table_id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name      = "Route table public"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this_1.id
  }
  tags = {
    Name      = "Route table private"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "priv_1" {
  count          = 2
  subnet_id      = element(aws_subnet.priv1.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv_2" {
  count          = 2
  subnet_id      = element(aws_subnet.priv2.*.id, count.index)
  route_table_id = aws_route_table.private.id
}