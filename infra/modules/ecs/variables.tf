variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ecr_repository_url" {
  type = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "desired_count" {
  type = number
}

variable "task_cpu" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "image_tag" {
  type = string
}

variable "enable_autoscaling" {
  type = bool
}

variable "autoscaling_min_capacity" {
  type = number
  default = 2
}

variable "autoscaling_max_capacity" {
  type = number
  default = 10
}
