variable "project_name" {
  description = "Prefix for AWS resources; matches ECR repo and ECS container name (fastapi-translation)."
  type        = string
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "container_port" {
  description = "Port the FastAPI app listens on inside the container."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/health"
}

variable "desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU). ML models need at least 2048."
  type        = number
  default     = 2048
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 4096
}

variable "enable_autoscaling" {
  description = "Enable ECS service CPU autoscaling (prod)."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum task count when autoscaling is enabled."
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum task count when autoscaling is enabled."
  type        = number
  default     = 10
}

variable "image_tag" {
  description = "Docker image tag pushed to ECR."
  type        = string
  default     = "latest"
}
