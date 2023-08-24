
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "compute" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "compute"
  }
}

resource "aws_route_table" "compute_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Compute Route Table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.compute.id
  route_table_id = aws_route_table.compute_rt.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# creating security group
resource "aws_security_group" "ec2-sg" {
  name   = "ec2-web-security-group"
  vpc_id = aws_vpc.main.id
  ingress = [
    {
      # ssh port allowed from any ip
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      # http port allowed from any ip
      description      = "http"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null   
    },
    {
      # http port allowed from any ip
      description      = "https"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null   
    }
  ]
  egress = [
    {
      description      = "all-open"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
  tags = {
    "Name"      = "terraform-ec2-sg"
    "terraform" = "true"
  }
}

data "aws_key_pair" "ec2_key" {
  key_pair_id           = var.VM_KEY_ID
}

data "aws_ssm_parameter" "amzn2-ami-latest" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


resource "aws_instance" "web_server" {
  ami           = data.aws_ssm_parameter.amzn2-ami-latest.value
  instance_type = "t2.micro"  
  key_name      = data.aws_key_pair.ec2_key.key_name
  subnet_id     = aws_subnet.compute.id
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.ec2-sg.id ]
  iam_instance_profile = aws_iam_instance_profile.ec2_web_profile.id
  tags = {
    Name = "octovmwebserver"
  }

  user_data = file("${path.module}/ec2_user_data.tpl")
  depends_on = [ aws_s3_bucket.static,aws_s3_object.assets ]
}


# S3 Bucket details
resource "aws_s3_bucket" "static" {
  // important to provide a global unique bucket name
  bucket = "octovmwebsitearm"
}

resource "aws_s3_object" "assets" {
  bucket = aws_s3_bucket.static.id
  key    = "deployment.zip"
  source = "${path.module}/deployment.zip"
  etag   = filemd5("${path.module}/deployment.zip")
}

resource "aws_s3_bucket_public_access_block" "some_bucket_access" {
  bucket = aws_s3_bucket.static.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}