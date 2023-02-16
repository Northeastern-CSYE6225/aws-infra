data "aws_availability_zones" "available" {
  state = var.az_state
}


# Create VPC
resource "aws_vpc" "assignment3" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
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

# Create 3 public subnets, each in different availability zones in the same region as the VPC
resource "aws_subnet" "public-subnet" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.assignment3.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "public-subnet-rta" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

# Create 3 private subnets, each in different availability zones in the same region as the VPC
resource "aws_subnet" "private-subnet" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.assignment3.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "private-subnet-rta" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}
