# ========================= #
# === S3 Bucket details === #
# ========================= #

# S3 bucket for website
resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${var.domain_name}"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octos3websitearm",
    })
  )}" 
}

resource "aws_s3_bucket_ownership_controls" "www_bucket_acl_ownership" {
  bucket = aws_s3_bucket.www_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "www_bucket_access" {
  bucket = aws_s3_bucket.www_bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "www_bucket_S3_public_read_only" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = templatefile("${path.module}/policy/s3-public-read-policy.json", { bucket = "www.${var.domain_name}" })
}

resource "aws_s3_bucket_cors_configuration" "www_bucket_cors_configuration" {
  bucket = aws_s3_bucket.www_bucket.id

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://www.${var.domain_name}"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_acl" "www_bucket_acl" {
  bucket = aws_s3_bucket.www_bucket.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.www_bucket_acl_ownership]
}

resource "aws_s3_bucket_website_configuration" "www_bucket_config" {
  bucket = aws_s3_bucket.www_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
  

# S3 bucket for redirecting non-www to www
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.domain_name

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octos3rootwebsitearm",
    })
  )}" 
}

resource "aws_s3_bucket_ownership_controls" "root_bucket_acl_ownership" {
  bucket = aws_s3_bucket.root_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "root_bucket_access" {
  bucket = aws_s3_bucket.root_bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "root_bucket_S3_public_read_only" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = templatefile("${path.module}/policy/s3-public-read-policy.json", { bucket = var.domain_name })
}

resource "aws_s3_bucket_acl" "root_bucket_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.root_bucket_acl_ownership]
}

resource "aws_s3_bucket_website_configuration" "root_bucket_config" {
  bucket = aws_s3_bucket.root_bucket.id

  redirect_all_requests_to {
    host_name = "https://www.${var.domain_name}"
  }
}

# S3 Object - This is used to deploy code to the S3 bucket
resource "aws_s3_object" "s3_assets" {
  for_each = fileset("${path.module}/../frontend/", "*")

  bucket = aws_s3_bucket.www_bucket.id
  key = each.value
  source = "${path.module}/../frontend/${each.value}"
  etag = filemd5("${path.module}/../frontend/${each.value}")
}