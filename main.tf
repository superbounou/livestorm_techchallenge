provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# ---------------------------------------------------------------------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------------------------------------------------------------------

module "network" {
  source         = "./modules/network"
  env            = var.env
  region         = var.region
  vpc_cidr_block = var.vpc_cidr_block
}

# ---------------------------------------------------------------------------------------------------------------------
# BASTION
# ---------------------------------------------------------------------------------------------------------------------

module "bastion" {
  source      = "./modules/bastion"
  vpc_id      = module.network.aws_vpc.id
  vpc_subnets = module.network.vpc_subnets_pub
  key_name    = var.key_name
}

# ---------------------------------------------------------------------------------------------------------------------
# WEBSERVER
# ---------------------------------------------------------------------------------------------------------------------

module "webserver" {
  source            = "./modules/webserver"
  vpc_id            = module.network.aws_vpc.id
  vpc_subnets       = module.network.vpc_subnets_priv
  key_name          = var.key_name
  instance_type     = var.instance_type
  enable_ssh_access = true
}
