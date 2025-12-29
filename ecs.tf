terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "clixx_ecs_cluster" {
  name = "clixx-ecs-cluster"
  
}

resource "aws_ecs_task_definition" "clixx_task" {
  family                   = "clixx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "clixx-cont"
      image     = "055081916963.dkr.ecr.us-east-1.amazonaws.com/clixx-repository:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "clixx_service" {
  name            = "clixx-service"
  cluster         = aws_ecs_cluster.clixx_ecs_cluster.id
  task_definition = aws_ecs_task_definition.clixx_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"] # Replace with your subnet IDs
    security_groups = ["sg-zzzzzzzz"] # Replace with your security group ID
    assign_public_ip = true
  }
}

