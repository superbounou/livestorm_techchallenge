variable "name" {
  type        = string
  description = "(Optional) Name that will be used in resources names and tags."
  default     = "http-server"
}

variable "key_name" {
  type        = string
  description = "The name of the key pair."
}

variable "instance_type" {
  type        = string
  description = "The instance type of the EC2 instance."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "vpc_subnets" {
  type        = list(string)
  description = "A list of VPC subnet IDs."
}

variable "enable_ssh_access" {
  description = "(Optional) Whether to allow SSH access or not. Requires SSH Key to be imported to AWS Console."
  type        = bool
  default     = false
}

variable "enable_recording_streaming" {
  description = "(Optional) Enables recording and streaming capability on Jitsi Meet"
  type        = bool
  default     = false
}
