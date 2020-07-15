variable "name" {
  type        = string
  description = "Name that will be used in resources names and tags."
  default     = "ssh-bastion"
}

variable "key_name" {
  type        = string
  description = "The name of the key pair"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "The instance type of the EC2 instance."
  default     = "t3.micro"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID."
}

variable "ingress_cidr_block" {
  type        = string
  description = "The CIDR IP range that is permitted to SSH to bastion instance."
  default     = "0.0.0.0/0"
}