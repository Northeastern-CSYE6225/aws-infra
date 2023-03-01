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
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "https from Anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks      = [aws_vpc.vpc.cidr_block]
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
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_profile.name

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  user_data = <<EOF
#!/bin/bash
cd /home/ec2-user/webapp/
touch .env
echo "API_PORT=3000" >> .env
echo "DB_HOST=${aws_db_instance.database.address}" >> .env
echo "DB_DATABASE=${aws_db_instance.database.db_name}" >> .env
echo "DB_USER=${aws_db_instance.database.username}" >> .env
echo "DB_PASSWORD=${aws_db_instance.database.password}" >> .env
echo "AWS_REGION=${var.region}" >> .env
echo "AWS_S3_BUCKET_NAME=${aws_s3_bucket.bucket.bucket}" >> .env
echo "MULTER_UPLOADS_DIR=/tmp/webapp-multer-uploads >> .env
sudo systemctl enable webapp.service
sudo systemctl start webapp.service
EOF

  tags = {
    Name = "webapp"
  }
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "webapp_s3_policy"
  path        = "/"
  description = "Allow webapp s3 access"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "webapp_s3_access_role" {
  name = "webapp_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2_s3_policy_role" {
  name       = "webapp_s3_attachment"
  roles      = [aws_iam_role.webapp_s3_access_role.name]
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "webapp_s3_profile"
  role = aws_iam_role.webapp_s3_access_role.name
}
