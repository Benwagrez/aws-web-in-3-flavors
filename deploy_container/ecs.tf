# ======================== #
# ====== ECS Cluster ===== #
# ======================== #
# Purpose
# Creates an ECS cluster and task for web hosting

# ECS Task definition with the container definition
resource "aws_ecs_task_definition" "taskDefinition" {
  cpu                      = 1024
  memory                   = 2048
  family                   = "ecs-web-task"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      "name"      = "ecs-web-container"
      "image"     = "${aws_ecr_repository.repository.repository_url}:latest"
      "essential" = true
      "memoryReservation" : 300,

      "portMappings" = [
        {
          "hostPort" : 80,
          "protocol" : "tcp",
          "containerPort" : 80
        }
      ]
    }
  ])
}

# ECS cluster 
resource "aws_ecs_cluster" "cluster" {
  name = "ecs-web-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# ECS service to manage ECS tasks and desired container state
resource "aws_ecs_service" "ecsService" {
  name            = "ecs-web-service"
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.taskDefinition.arn

  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true

  health_check_grace_period_seconds = 10

  network_configuration {
    subnets          = [ aws_subnet.compute_zonea.id, aws_subnet.compute_zoneb.id ]
    security_groups  = [ aws_security_group.ecs-sg.id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_servers.arn
    container_name   = "ecs-web-container"
    container_port   = 80
  }

  # ask terraform to ignore changes to the task definition since we update that externally
  lifecycle {
    ignore_changes = [task_definition]
  }
}