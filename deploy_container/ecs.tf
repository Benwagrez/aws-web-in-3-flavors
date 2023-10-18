resource "aws_ecs_task_definition" "taskDefinition" {
  family                   = "ecs-web-task"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  container_definitions = jsonencode([
    {
      "name"      = "ecs-web-container"
      "image"     = "${aws_ecr_repository.repository.repository_url}:latest"
      "essential" = true
      "memoryReservation" : 300,

      "portMappings" = [
        {
          "hostPort" = 8080
          "protocol" : "tcp",
          "containerPort" = 80
        }
      ]
    }
  ])
}


resource "aws_ecs_cluster" "cluster" {
  name = "ecs-web-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_service" "ecsService" {
  name            = "ecs-web-service"
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.taskDefinition.arn
  iam_role        = aws_iam_role.ecsServiceRole.arn

  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true

  health_check_grace_period_seconds = 10

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_servers.arn
    container_name   = "ecs-web-container"
    container_port   = 8080
  }

  # ask terraform to ignore changes to the task definition since we update that externally
  lifecycle {
    ignore_changes = [task_definition]
  }
}