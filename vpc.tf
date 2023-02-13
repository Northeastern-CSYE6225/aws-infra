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

# Create a public route table. Attach all public subnets to this route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.assignment3.id

  route {
    cidr_block = var.public_route_table_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public"
  }
}

# Create a private route table. Attach all private subnets to this route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.assignment3.id

  route {
    cidr_block = var.private_route_table_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "private"
  }
}
