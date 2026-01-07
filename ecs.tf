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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "jenkins_sg" {
  id = "sg-0029e71213e91bfff"
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  owners = ["self", "186769093804"]
}

data "aws_ecr_repository" "clixx_repo" {
  name = "clixx-repository"
}

data "aws_ecr_image" "clixx_image" {
  repository_name = "clixx-repository"
  image_tag       = "latest" 
}

resource "aws_db_instance" "clixx_rds_instance" {
  identifier              = "clixx-db"
  instance_class          = "db.t4g.micro"
  engine                  = "mysql"
  snapshot_identifier     = "wordpressdbclixxsnap"
  skip_final_snapshot     = true
  publicly_accessible     = false

  vpc_security_group_ids  = [data.aws_security_group.jenkins_sg.id]
}

resource "aws_ecs_cluster" "clixx_ecs_cluster" {
  name = "clixx-ecs-cluster"
}

resource "aws_ecs_task_definition" "clixx_task" {
  family                   = "clixx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name"      = "clixx-cont"
      "image"     = "${data.aws_ecr_repository.clixx_repo.repository_url}@${data.aws_ecr_image.clixx_image.image_digest}"
      "essential" = true
      "portMappings" = [
        {
          "containerPort" = 80
          "hostPort"      = 80
          "protocol"      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_lb" "clixx_nlb" {
  name               = "clixx-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in data.aws_subnet.public : subnet.id]

  tags = {
    Environment = "automation"
  }
}

resource "aws_lb_target_group" "clixx_tg" {
  name     = "clixx-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    protocol            = "TCP"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "clixx_listener" {
  load_balancer_arn = aws_lb.clixx_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clixx_tg.arn
  }
}

resource "aws_launch_template" "clixx_lt" {
  name_prefix   = "clixx-lt-"
  image_id      = data.aws_ami.ecs_ami.id
  instance_type = var.instance_type

  user_data = filebase64("${path.module}/scripts/userdata.sh")

  iam_instance_profile {
    name = "ec2_instance_role" 
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [data.aws_security_group.jenkins_sg.id]
  }  
}

resource "aws_autoscaling_group" "clixx_asg" {
  name = "clixx-asg"
  target_group_arns = [aws_lb_target_group.clixx_tg.arn]

  min_size = 1
  max_size = 3

  launch_template {
    id      = aws_launch_template.clixx_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.default.ids

  tag {
    key                 = "Name"
    value               = "clixx-asg"
    propagate_at_launch = true
  }
}

resource "aws_ecs_service" "clixx_service" {
  name            = "clixx-service"
  cluster         = aws_ecs_cluster.clixx_ecs_cluster.id
  task_definition = aws_ecs_task_definition.clixx_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  force_new_deployment = true

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [data.aws_security_group.jenkins_sg.id] 
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "packer-ami-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.clixx_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80 
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.clixx_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ec2.name]
}
