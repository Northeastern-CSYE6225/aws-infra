variable "region" {
  description = "VPC region"
  default     = "us-east-1"
  type        = string
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
  type        = string
}

variable "public_route_table_cidr_block" {
  description = "Public route table CIDR block"
  default     = "0.0.0.0/0"
  type        = string
}

variable "private_route_table_cidr_block" {
  description = "Private route table CIDR block"
  default     = "10.1.0.0/16"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks and availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks and availability zones"
  type        = list(string)
}

variable "az_state" {
  description = "Availability zone state"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  type        = string
}

variable "public_key" {
  description = "SSH public key"
  type        = string
}

variable "domain_name" {
  description = "domain name for A record"
  type        = string
}
