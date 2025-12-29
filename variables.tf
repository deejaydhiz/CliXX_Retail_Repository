variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
}
variable "security_group_ids" {
  description = "List of security group IDs for the ECS service"
  type        = list(string)
}
variable "desired_count" {
  description = "The desired number of ECS service tasks"
  type        = number
  default     = 1
}
variable "container_image" {
  description = "The container image for the ECS task"
  type        = string
  default     = "055081916963.dkr.ecr.us-east-1.amazonaws.com/clixx-repository:latest"
}
variable "container_port" {
  description = "The port on which the container listens"
  type        = number
  default     = 80
}   
variable "cpu" {
  description = "The amount of CPU to allocate to the ECS task"
  type        = string
  default     = "256"
}
variable "memory" {
  description = "The amount of memory to allocate to the ECS task"
  type        = string
  default     = "512"
}   

variable "task_family" {
  description = "The family name of the ECS task"
  type        = string
  default     = "clixx-task"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "clixx-ecs-cluster"
}
variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "clixx-service"
}
variable "launch_type" {
  description = "The launch type for the ECS service"
  type        = string
  default     = "FARGATE"
}

