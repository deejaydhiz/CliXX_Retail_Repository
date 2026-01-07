variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "automation"
}

variable "ami_name" {
  description = "Name of the ECS AMI"
  type        = string
  default     = "stack14-ecs_ami"
}

variable "instance_type" {
  description = "EC2 instance type for ECS tasks"
  type        = string
  default     = "t3.micro"
}