resource "aws_s3_bucket" "backupBucket" {
  bucket = "${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}"
  force_destroy = true
  tags = local.tags
}

resource "aws_s3_access_point" "backupBucket_access_point" {
  bucket = aws_s3_bucket.backupBucket.id
  name   = "${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}"

  # VPC must be specified for S3 on Outposts
  vpc_configuration {
    vpc_id = data.aws_vpc.default.id
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.backupBucket.id

  rule {
    id = "delete-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.backupBucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "bucketacl" {
  bucket = aws_s3_bucket.backupBucket.id
  acl    = "private"
}