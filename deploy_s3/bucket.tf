# ========================= #
# === S3 Bucket details === #
# ========================= #
# Purpose
# Deploy two S3 website buckets for root and www domains
# Deploy frontend to the www bucket
#
# Notes
# You're going to hate S3 buckets in Terraform after reading this code, so many different resources

############################################
########## S3 bucket for website ##########
############################################
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

  block_public_acls       = true 
  block_public_policy     = true # true
  ignore_public_acls      = true # true
  restrict_public_buckets = true 
}

resource "aws_s3_bucket_policy" "www_bucket_S3_private_read_only" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = templatefile("${path.module}/bucket_policy/s3-private-read-policy-OAC.json", { bucket = "www.${var.domain_name}", AWSTERRAFORMSPN = var.TerraformSPNArn, cloudfront = aws_cloudfront_distribution.www_s3_distribution.arn})
  depends_on = [aws_s3_bucket_ownership_controls.www_bucket_acl_ownership]
}

resource "aws_s3_bucket_cors_configuration" "www_bucket_cors_configuration" {
  bucket = aws_s3_bucket.www_bucket.id

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://www.${var.domain_name}","https://${var.domain_name}"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_acl" "www_bucket_acl" {
  bucket = aws_s3_bucket.www_bucket.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.www_bucket_acl_ownership]
}

# resource "aws_s3_bucket_website_configuration" "www_bucket_config" {
#   bucket = aws_s3_bucket.www_bucket.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "error.html"
#   }
# }

  
############################################
# S3 bucket for redirecting non-www to www #
############################################
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

  block_public_acls       = true 
  block_public_policy     = true # true
  ignore_public_acls      = true # true
  restrict_public_buckets = true 
}

resource "aws_s3_bucket_policy" "root_bucket_S3_private_read_only" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = templatefile("${path.module}/bucket_policy/s3-private-read-policy-OAC.json", { bucket = var.domain_name, AWSTERRAFORMSPN = var.TerraformSPNArn, cloudfront = aws_cloudfront_distribution.www_s3_distribution.arn})
  depends_on = [aws_s3_bucket_ownership_controls.root_bucket_acl_ownership]
}

resource "aws_s3_bucket_acl" "root_bucket_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.root_bucket_acl_ownership]
}

# resource "aws_s3_bucket_website_configuration" "root_bucket_config" {
#   bucket = aws_s3_bucket.root_bucket.id

#   redirect_all_requests_to {
#     host_name = "www.${var.domain_name}"
#     protocol  = "https"
#   }
# }


############################################
########### Frontend Deployment ############
############################################
# Module to ingest frontend files and append content attributes to the files
# This is necessary for the S3 object upload so S3 can receive the content type
# OTherwise instead of displaying your lovely webpage it will download it
module "content_attached_files" {
  source = "hashicorp/dir/template"

  base_dir = "${path.module}/../frontend/"

}

# S3 Object - This is used to deploy the website to the S3 bucket
# It runs a loop through every file in the frontend/ folder and uploads 
# the file with metadata derived from the content_attached_file module
resource "aws_s3_object" "s3_assets" {
  for_each     = module.content_attached_files.files 

  bucket       = aws_s3_bucket.www_bucket.id
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content
  etag         = each.value.digests.md5
}