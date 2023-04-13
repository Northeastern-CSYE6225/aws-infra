resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_kms_key" "rds" {
  description              = "RDS KMS key"
  deletion_window_in_days  = 10
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  multi_region             = true
  policy = jsonencode(

    {
      "Id" : "key-for-rds",
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "Allow use of the key",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
          },
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Allow attachment of persistent resources",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
          },
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource" : "*",
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        }
      ]
    }

  )
}

resource "aws_db_instance" "database" {
  allocated_storage      = 10
  db_name                = "csye6225"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "csye6225"
  password               = random_password.password.result
  parameter_group_name   = aws_db_parameter_group.mysql57_pg.name
  skip_final_snapshot    = true
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.database.id
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
}

resource "aws_security_group" "database_sg" {
  name        = "database"
  description = "Allow inbound traffic to 3306 from VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "open port 3306 to vpc"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp_sg.id]
  }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = -1
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "database"
  }
}

resource "aws_db_subnet_group" "database" {
  name       = "database"
  subnet_ids = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id]

  tags = {
    Name = "database subnet group"
  }
}

resource "aws_db_parameter_group" "mysql57_pg" {
  name   = "webapp-database-pg"
  family = "mysql5.7"
}
