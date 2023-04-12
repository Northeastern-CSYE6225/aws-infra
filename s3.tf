resource "random_uuid" "uuid" {
}

resource "aws_s3_bucket" "bucket" {
  bucket        = random_uuid.uuid.result
  force_destroy = true

  tags = {
    Name        = "CSYE 6225 webapp"
    Environment = var.profile
  }
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_ownership_controls" "bucket_acl_ownership" {
#   bucket = aws_s3_bucket.bucket.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
#   # Add just this depends_on condition
#   depends_on = [aws_s3_bucket_acl.bucket_acl]
# }

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

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
