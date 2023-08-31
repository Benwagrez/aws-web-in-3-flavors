# ========================= #
# === S3 Bucket details === #
# ========================= #

# S3 bucket
resource "aws_s3_bucket" "s3_vm_bucket" {
  bucket = "octovmwebsitearm"
  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octovmwebsitearm",
    })
  )}"
}

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

# S3 Object - This is used to deploy code to the S3 bucket
resource "aws_s3_object" "vm_assets" {
  bucket = aws_s3_bucket.s3_vm_bucket.id
  key    = "deployment.zip"
  source = "${path.module}/../deployment.zip"
  etag   = filemd5("${path.module}/../deployment.zip")
}

# Bucket Public Access Disabled 
resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket = aws_s3_bucket.s3_vm_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}