data "aws_ami" "webapp_ami" {
  # executable_users = ["self"]
  most_recent = true
  # name_regex       = "csye6225_*"
  owners = ["061920653777"]

  filter {
    name   = "name"
    values = ["csye6225_*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "application_sg" {
  name        = "application"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.assignment3.id

  ingress {
    description = "https from Anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks      = [aws_vpc.assignment3.cidr_block]
  }

  ingress {
    description = "http from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom port for webapp"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "aws-key"
  public_key = var.public_key
}

resource "aws_instance" "webapp" {
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  ami                         = data.aws_ami.webapp_ami.id
  vpc_security_group_ids      = [aws_security_group.application_sg.id]
  subnet_id                   = aws_subnet.public-subnet[0].id
  disable_api_termination     = false
  key_name                    = aws_key_pair.deployer.key_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  tags = {
    Name = "webapp"
  }
}
