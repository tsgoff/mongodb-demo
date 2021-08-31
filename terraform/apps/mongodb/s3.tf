resource "aws_s3_bucket" "backupBucket" {
  bucket = "${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id = "delete-after-30-days"
    enabled = true
    prefix = ""

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      days = 30
    }
  }

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