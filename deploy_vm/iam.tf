# EC2 role and bucket policy

resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm-policy"
  path        = "/"
  description = "Allow"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:us-east-2:${var.AWS_ACCOUNT_ID}:parameter/octoweb/SSL/*"
        }
    ]
  })  
}

resource "aws_iam_policy" "bucket_policy" {
  name        = "web-bucket-policy"
  path        = "/"
  description = "Allow "

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowDeployBucket",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.static.arn}/*",
          "${aws_s3_bucket.static.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ec2_web_role" {
  name = "ec2_web_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bucket_policy_role_attachment" {
  role       = aws_iam_role.ec2_web_role.name
  policy_arn = aws_iam_policy.bucket_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_policy_role_attachment" {
  role       = aws_iam_role.ec2_web_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_readonly_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role       = aws_iam_role.ec2_web_role.name
}

resource "aws_iam_instance_profile" "ec2_web_profile" {
  name = "ec2-web-profile"
  role = aws_iam_role.ec2_web_role.name
}


