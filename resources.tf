terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "us-east-1" # Replace with your AWS region
}

# Variables for VPC and Subnet IDs
variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs in the existing VPC"
  type        = list(string)
}

# Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}

# Create ECR Repository
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "my-ecr-repo"
  image_tag_mutability = "MUTABLE"
  lifecycle_policy {
    policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 10,
      "description": "Expire untagged images after 30 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "terraform-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Definition
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Adjust based on your requirements
  memory                   = "512" # Adjust based on your requirements
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<EOF
[
  {
    "name": "my-container",
    "image": "${aws_ecr_repository.ecr_repo.repository_url}:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
EOF
}

# Output for ECR Repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

# Output for ECS Cluster Name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

