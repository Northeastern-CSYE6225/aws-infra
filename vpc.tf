# Create VPC
resource "aws_vpc" "assignment3" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "assignment3"
  }
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.assignment3.id
}
