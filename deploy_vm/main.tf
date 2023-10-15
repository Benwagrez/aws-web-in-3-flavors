# ========================= #
# ==== EC2 Web Server ===== #
# ========================= #
# Purpose
# Creating Auto Scaling Group with Linux VM for the webserver

# Setting terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

# Data reference for existing public key
data "aws_key_pair" "ec2_key" {
  key_pair_id = var.VM_KEY_ID
}

# Data reference for SSM parameter pointing to latest Amazon AMI image
data "aws_ssm_parameter" "amzn2-ami-latest" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2 instance to host the web server
resource "aws_launch_template" "webserver_launch_configuration" {
  name = "octowebserver_launch_configuration"
  image_id = data.aws_ssm_parameter.amzn2-ami-latest.value
  instance_type = "t2.micro"
  user_data = base64encode(file("${path.module}/ec2_user_data.tpl"))
  key_name = data.aws_key_pair.ec2_key.key_name

  iam_instance_profile {
    arn  = aws_iam_instance_profile.ec2_web_profile.arn
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.ec2-sg.id ]
  }  
}

resource "aws_placement_group" "placement_spread" {
  name     = "Web Server Placement Group"
  strategy = "spread"
}

resource "random_id" "dynamic" {
  keepers = {
    # Generate a new id each time we change the deployment package
    code_hash = filemd5("${path.module}/../deployment.zip")
  }

  byte_length = 8
}

resource "aws_autoscaling_group" "web_server_asg" {
  name                      = "octoasggroup"
  max_size                  = 1
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  placement_group           = aws_placement_group.placement_spread.id
  vpc_zone_identifier       = [ aws_subnet.compute_zonea.id, aws_subnet.compute_zoneb.id ]

  # launch_configuration      = aws_launch_configuration.webserver_launch_configuration.name
  launch_template {
    id      = aws_launch_template.webserver_launch_configuration.id
    version = aws_launch_template.webserver_launch_configuration.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    triggers = ["tag"]
  }
  tag {
    key                 = "Name"
    value               = "octowebserver"
    propagate_at_launch = true
  }
  tag {
    key                 = "ContentID"
    value               = random_id.dynamic.id
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.common_tags

    content {
      key    =  tag.key
      value   =  tag.value
      propagate_at_launch =  true
    }
  } 
  timeouts {
    delete = "15m"
  }

  depends_on = [ aws_s3_bucket.s3_vm_bucket,aws_s3_object.vm_assets ]
}