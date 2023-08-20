resource "aws_s3_bucket" "static" {
  // important to provide a global unique bucket name
  bucket = "octos3websitearm2023"
}

resource "aws_s3_bucket_acl" "static" {
  bucket = aws_s3_bucket.static.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.static.id
  ignore_public_acls      = true
  block_public_acls       = true
  restrict_public_buckets = true
  block_public_policy     = true
}

locals {
  content_type_map = {
    css:  "text/css; charset=UTF-8"
    js:   "text/js; charset=UTF-8"
    svg:  "image/svg+xml"
  }
}

resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  index_document {
    suffix = "index.html"
  }

  routing_rule {
    redirect {
      replace_key_with = "index.html"
    }
  }
}

resource "aws_s3_object" "assets" {
  for_each = fileset("${path.module}/frontend", "**")

  bucket = aws_s3_bucket.static.id
  key    = each.value
  source = "${path.module}/frontend/${each.value}"
  etag   = filemd5("${path.module}/frontend/${each.value}")

  // simplification of the content type serving
  content_type = lookup(
    local.content_type_map,
    split(".", basename(each.value))[length(split(".", basename(each.value))) - 1],
    "text/html; charset=UTF-8",
  )
}