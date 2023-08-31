# ========================= #
# === S3 Bucket details === #
# ========================= #
# Purpose
# Deploy S3 bucket and frontend contents as zipped into S3 bucket
# for retrieval on the EC2 instance

# S3 bucket for zip contents
resource "aws_s3_bucket" "s3_vm_bucket" {
  bucket = "octovmwebsitearm"
  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octovmwebsitearm",
    })
  )}"
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