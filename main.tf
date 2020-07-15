provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# ---------------------------------------------------------------------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "livestream_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name      = "livestream VPC"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_subnet" "livestream_pubsubnet" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 1, 0)
  availability_zone = var.az
  vpc_id            = aws_vpc.livestream_vpc.id
  tags = {
    Name      = "Public subnet"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_subnet" "livestream_privsubnet" {
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 1, 1)
  availability_zone = var.az
  vpc_id            = aws_vpc.livestream_vpc.id
  tags = {
    Name      = "Private subnet"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_internet_gateway" "livestream_ig" {
  vpc_id = aws_vpc.livestream_vpc.id
  tags = {
    Name      = "Internet Gateway"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_eip" "livestream_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.livestream_ig]
  tags = {
    Name      = "Elastic IP for NatGW"
    Terraform = "true"
    Env       = var.env
  }
}


resource "aws_nat_gateway" "livestream_natgw" {
  allocation_id = aws_eip.livestream_eip.id
  subnet_id     = aws_subnet.livestream_pubsubnet.id
  depends_on    = [aws_internet_gateway.livestream_ig]
  tags = {
    Name      = "Nat gateway"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_route" "livestream_route" {
  route_table_id         = aws_vpc.livestream_vpc.default_route_table_id
  gateway_id             = aws_internet_gateway.livestream_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "livestream_route_public" {
  vpc_id = aws_vpc.livestream_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.livestream_ig.id
  }
  tags = {
    Name      = "Route table public"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_route_table" "livestream_route_private" {
  vpc_id = aws_vpc.livestream_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.livestream_natgw.id
  }
  tags = {
    Name      = "Route table private"
    Terraform = "true"
    Env       = var.env
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.livestream_pubsubnet.id
  route_table_id = aws_route_table.livestream_route_public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.livestream_privsubnet.*.id, count.index)
  route_table_id = aws_route_table.livestream_route_private.id
}

# ---------------------------------------------------------------------------------------------------------------------
# BASTION
# ---------------------------------------------------------------------------------------------------------------------

module "bastion" {
  source    = "./modules/bastion"
  vpc_id    = aws_vpc.livestream_vpc.id
  subnet_id = aws_subnet.livestream_pubsubnet.id
  key_name  = var.key_name
}

# ---------------------------------------------------------------------------------------------------------------------
# WEBSERVER
# ---------------------------------------------------------------------------------------------------------------------

module "webserver" {
  source            = "./modules/webserver"
  vpc_id            = aws_vpc.livestream_vpc.id
  subnet_id         = aws_subnet.livestream_privsubnet.id
  key_name          = var.key_name
  instance_type     = "t2.micro"
  enable_ssh_access = true
}
