variable "env" {
  default = "testing"
  type    = string
}

variable "key_name" {
  default = "terraform"
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
  default = "10.0.0.0/16"
  type    = string
}

variable "region" {
  default = "us-east-1"
  type    = string
}

variable "az_a" {
  default = "us-east-1a"
  type    = string
}

variable "az_b" {
  default = "us-east-1b"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "domain" {
  default = "bounou.io"
  type    = string
}

variable "sub_domain" {
  default = "livestorm.bounou.io"
  type    = string
}