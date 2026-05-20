# Dev: 1 task, no autoscaling — app: fastapi-translation
project_name       = "fastapi-translation"
aws_region         = "us-east-1"
container_port     = 3000
health_check_path  = "/health"
desired_count      = 1
task_cpu           = 2048
task_memory        = 4096
enable_autoscaling = false
image_tag          = "latest"
