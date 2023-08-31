# ========================= #
# ====== Networking ======= #
# ========================= #

# AWS VPC 
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Web VPC",
    })
  )}"  
}

# Subnet hosted in main AWS VPC
resource "aws_subnet" "compute_zonea" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.100.0/24"
  availability_zone = "us-east-2a"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet",
    })
  )}"  
}

resource "aws_subnet" "compute_zoneb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-2b"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet",
    })
  )}"  
}

# Load Balancer Subnets hosted in main AWS VPC
resource "aws_subnet" "lb_zonea" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "us-east-2a"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet",
    })
  )}"  
}

resource "aws_subnet" "lb_zoneb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.51.0/24"
  availability_zone = "us-east-2b"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet",
    })
  )}"  
}

# Route Table for internet gateway default route
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

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute route table",
    })
  )}"  
}

resource "aws_lb" "alb" {
  name               = "octoappbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.app-gw-sg.id ]
  subnets            = [ aws_subnet.lb_zonea.id, aws_subnet.lb_zoneb.id ]


  # access_logs {
  #   bucket  = aws_s3_bucket.static.id
  #   prefix  = "alb"
  #   enabled = true
  # }

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octoappbalancer",
    })
  )}" 
}

resource "aws_lb_listener" "web_front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }
}

resource "aws_lb_target_group" "web_servers" {
  name     = "web-server-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
}

resource "aws_autoscaling_attachment" "web_servers_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.id
  lb_target_group_arn   = aws_lb_target_group.web_servers.arn
}

# Attaching route table to subnet
resource "aws_route_table_association" "route_table_assoc" {
  subnet_id      = aws_subnet.lb_zonea.id
  route_table_id = aws_route_table.compute_rt.id
}

resource "aws_route_table_association" "route_table_assoc2" {
  subnet_id      = aws_subnet.lb_zoneb.id
  route_table_id = aws_route_table.compute_rt.id
}

resource "aws_route_table_association" "route_table_assoc3" {
  subnet_id      = aws_subnet.compute_zonea.id
  route_table_id = aws_route_table.compute_rt.id
}

resource "aws_route_table_association" "route_table_assoc4" {
  subnet_id      = aws_subnet.compute_zoneb.id
  route_table_id = aws_route_table.compute_rt.id
}

# Creating internet gateway to allow bi-drectional traffic between public and private VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Web Internet Gateway",
    })
  )}"  
}

# Creating security group to restrict traffic to SSH and HTTPS
resource "aws_security_group" "app-gw-sg" {
  name   = "Web-security-group"
  vpc_id = aws_vpc.main.id
  ingress = [
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
  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Web Network Security Gateway",
    })
  )}"  
}

# Creating security group to restrict traffic to SSH and HTTPS
resource "aws_security_group" "ec2-sg" {
  name   = "Compute-security-group"
  vpc_id = aws_vpc.main.id
  ingress = [
    {
      # http port allowed from any ip
      description      = "https"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = null
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups = [ aws_security_group.app-gw-sg.id ]
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
  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Web Network Security Gateway",
    })
  )}"  
}