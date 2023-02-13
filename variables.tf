variable "region" {
  description = "VPC region"
  default     = "us-east-1"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
  type        = string
}
