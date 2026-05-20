# Prod: 2 tasks, CPU autoscaling 2–10 — app: fastapi-translation
project_name             = "fastapi-translation"
aws_region               = "us-east-1"
container_port           = 3000
health_check_path        = "/health"
desired_count            = 2
task_cpu                 = 2048
task_memory              = 4096
enable_autoscaling       = true
autoscaling_min_capacity = 2
autoscaling_max_capacity = 10
image_tag                = "latest"
