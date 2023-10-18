# ========================= #
# ====== Networking ======= #
# ========================= #
# Purpose
# Create networking to support ECS and application load balancer
# Including network hardening resources for security

# AWS VPC 
resource "aws_vpc" "main" {
  cidr_block       = "10.2.0.0/16"
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
  cidr_block        = "10.2.100.0/24"
  availability_zone = "us-east-2a"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet A",
    })
  )}"  
}

resource "aws_subnet" "compute_zoneb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.101.0/24"
  availability_zone = "us-east-2b"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Compute Subnet B",
    })
  )}"  
}

# Load Balancer Subnets hosted in main AWS VPC
resource "aws_subnet" "lb_zonea" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.50.0/24"
  availability_zone = "us-east-2a"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Loadbalancer Subnet A",
    })
  )}"  
}

resource "aws_subnet" "lb_zoneb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.51.0/24"
  availability_zone = "us-east-2b"

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "Loadbalancer Subnet B",
    })
  )}"  
}

# Route Table for internet gateway default route
resource "aws_route_table" "lb_rt" {
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
      "Name" = "Loadbalancer route table",
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

  # Ideally would not have internet, but don't want to pay for private link or S3 gateway
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

# Application load balancer for frontend traffic
resource "aws_lb" "alb" {
  name               = "ecsappbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.app-gw-sg.id ]
  subnets            = [ aws_subnet.lb_zonea.id, aws_subnet.lb_zoneb.id ]
  enable_http2       = true

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "octoappbalancer",
    })
  )}" 
}

# Adding an HTTP listener to the alb to redirect to HTTPS
resource "aws_lb_listener" "web_front_end_no_ssl" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Adding an HTTPS listener that will forward to target group of the web Auto Scaling Group
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

  tags = "${merge(
    var.common_tags,
    tomap({
      "Name" = "web_listener",
    })
  )}"
}

# Creating the target group for the web auto scaling group
resource "aws_lb_target_group" "web_servers" {
  name        = "web-server-tg"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

# Attaching route table to subnets
resource "aws_route_table_association" "route_table_assoc" {
  subnet_id      = aws_subnet.lb_zonea.id
  route_table_id = aws_route_table.lb_rt.id
}

resource "aws_route_table_association" "route_table_assoc2" {
  subnet_id      = aws_subnet.lb_zoneb.id
  route_table_id = aws_route_table.lb_rt.id
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
      "Name" = "ECS Web Internet Gateway",
    })
  )}"  
}

# Creating security group to restrict traffic to SSH and HTTPS
resource "aws_security_group" "app-gw-sg" {
  name   = "ECS-Web-security-group"
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
resource "aws_security_group" "ecs-sg" {
  name   = "ECS-security-group"
  vpc_id = aws_vpc.main.id
  ingress = [
    {
      # http port allowed from any ip
      description      = "http"
      from_port        = 80
      to_port          = 80
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