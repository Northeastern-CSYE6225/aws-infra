# Create VPC
resource "aws_vpc" "assignment3" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "assignment3"
  }
}
