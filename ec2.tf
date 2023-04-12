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

data "template_file" "user_data" {
  template = <<EOF
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
sudo systemctl enable webapp.service
sudo systemctl start webapp.service
EOF
}

resource "aws_security_group" "webapp_sg" {
  name        = "WebAppSecurityGroup"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Custom port for webapp"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebAppSecurityGroup"
  }
}

resource "aws_key_pair" "deployer" {
  public_key = var.public_key
}

resource "aws_kms_key" "ebs" {
  description = "EBS KMS key"
  policy = jsonencode({
    "Id" : "key-for-ebs",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.id}:volume/*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:root"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.id}:volume/*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.id}:volume/*",

      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.id}:volume/*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}

resource "aws_launch_template" "lt" {
  name                                 = "asg_launch_config"
  image_id                             = data.aws_ami.webapp_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  key_name                             = aws_key_pair.deployer.key_name
  disable_api_termination              = false

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp2"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    # using vpc_security_group_ids instead
    security_groups = [aws_security_group.webapp_sg.id]
  }

  # vpc_security_group_ids = [aws_security_group.vpc.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "asg_launch_config"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "WebAppS3"
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

  tags = {
    Name = "WebAppS3"
  }
}

resource "aws_iam_role" "webapp_ec2_access_role" {
  name = "EC2-CSYE6225"

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

  tags = {
    Name = "EC2-CSYE6225"
  }
}

data "aws_iam_policy" "webapp_cloudwatch_server_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy_attachment" "ec2_s3_policy_role" {
  name       = "webapp_s3_attachment"
  roles      = [aws_iam_role.webapp_ec2_access_role.name]
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

resource "aws_iam_policy_attachment" "ec2_cloudwatch_policy_role" {
  name       = "webapp_cloudwatch_policy"
  roles      = [aws_iam_role.webapp_ec2_access_role.name]
  policy_arn = data.aws_iam_policy.webapp_cloudwatch_server_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "webapp_s3_profile"
  role = aws_iam_role.webapp_ec2_access_role.name
}
