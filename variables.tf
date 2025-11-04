variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  default     = "my-key"
}