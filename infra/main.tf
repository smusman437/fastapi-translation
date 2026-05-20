# Terraform root: fastapi-translation → AWS ECS Fargate
# Run via: ./scripts/plan.sh dev | ./scripts/deploy.sh dev

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Application = "fastapi-translation"
      ManagedBy   = "terraform"
    }
  }
}

# --- Networking: VPC + public subnets for ALB and Fargate ---

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  aws_region   = var.aws_region
}

# --- ECR: Docker images for fastapi-translation (force_delete for destroy.sh) ---

resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.project_name
    App  = "fastapi-translation"
  }
}

# --- ECS: cluster, ALB, Fargate service (ARM64) ---

module "ecs" {
  source = "./modules/ecs"

  project_name             = var.project_name
  aws_region               = var.aws_region
  vpc_id                   = module.networking.vpc_id
  public_subnet_ids        = module.networking.public_subnet_ids
  ecr_repository_url       = aws_ecr_repository.app.repository_url
  container_port           = var.container_port
  health_check_path        = var.health_check_path
  desired_count            = var.desired_count
  task_cpu                 = var.task_cpu
  task_memory              = var.task_memory
  image_tag                = var.image_tag
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
}

# --- Outputs used by scripts ---

output "ecr_uri" {
  description = "ECR repository URL for fastapi-translation images"
  value       = aws_ecr_repository.app.repository_url
}

output "api_url" {
  description = "Public ALB URL for the translator API"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "project_name" {
  value = var.project_name
}

output "container_port" {
  value = var.container_port
}
