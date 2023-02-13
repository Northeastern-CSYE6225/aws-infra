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
  type        = list(object({ cidr : string, az : string }))
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks and availability zones"
  type        = list(object({ cidr : string, az : string }))
}

# variable "vpcs" {
#   description = "VPC details"
#   type = list(object({
#     vpc_cidr_block                 = string
#     private_route_table_cidr_block = string
#     public_subnet_cidr_blocks      = list(string)
#     private_subnet_cidr_blocks     = list(string)
#   }))
#   default = [{
#     vpc_cidr_block                 = "10.0.0.0/16"
#     private_route_table_cidr_block = "10.1.0.0/16"
#     public_subnet_cidr_blocks      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#     private_subnet_cidr_blocks     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
#   }]
# }
