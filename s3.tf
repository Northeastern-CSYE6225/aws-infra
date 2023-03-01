resource "random_uuid" "uuid" {
}

resource "aws_s3_bucket" "bucket" {
  bucket = random_uuid.uuid.result

  tags = {
    Name        = "CSYE 6225 webapp"
    Environment = var.profile
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_config" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "move_to_IA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_kms_key" "bucket_key" {
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

