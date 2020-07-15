variable "env" {
  default = ""
  type    = string
}

variable "key_name" {
  default = ""
  type    = string
}

variable "access_key" {
  default = ""
  type    = string
}

variable "secret_key" {
  default = ""
  type    = string
}

variable "vpc_cidr_block" {
  default = ""
  type    = string
}

variable "region" {
  default = ""
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}
