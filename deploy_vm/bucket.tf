# ========================= #
# === S3 Bucket details === #
# ========================= #
# Purpose
# Deploy S3 bucket and frontend contents as zipped into S3 bucket
# for retrieval on the EC2 instance

# S3 bucket for zip contents and ALB access logs
resource "aws_s3_bucket" "s3_vm_bucket" {
  bucket = "octovmwebsitearm"
  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octovmwebsitearm",
    })
  )}"
}

# Granting alb access to S3 bucket
resource "aws_s3_bucket_policy" "allow_access_from_alb" {
  bucket = aws_s3_bucket.s3_vm_bucket.id
  policy = data.aws_iam_policy_document.allow_access_for_alb.json
}

# Generating bucket policy for alb access 
data "aws_iam_policy_document" "allow_access_for_alb" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["033677994240"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.s3_vm_bucket.arn}/alb/AWSLogs/*",
    ]
  }
}

# Configuring a storage lifecycle policy to save $$$
resource "aws_s3_bucket_lifecycle_configuration" "s3_vm_bucket_lifecycle_config" {
  bucket = aws_s3_bucket.s3_vm_bucket.id

  rule {
    id = "cleanup"
    status = "Enabled"

    expiration {
      days = 60
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# S3 Object - This is used to deploy the zipped website to the S3 bucket
resource "aws_s3_object" "vm_assets" {
  bucket = aws_s3_bucket.s3_vm_bucket.id
  key    = "deployment.zip"
  source = "${path.module}/../deployment.zip"
  etag   = filemd5("${path.module}/../deployment.zip")
}

# Bucket Public Access Disabled so bad guys go away
resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket = aws_s3_bucket.s3_vm_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}