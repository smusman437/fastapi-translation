# TERRAFORM.md — Infrastructure for fastapi-translation

## What is Terraform doing here?

Terraform creates and manages AWS resources for the **fastapi-translation** app. It does **not** build your Docker image by itself — scripts call `deploy-image.sh` after `apply`.

## Directory layout

```text
infra/
├── main.tf                 # Provider, ECR, wires networking + ECS modules
├── variables.tf            # Input variables
├── terraform.tfvars        # Dev values (1 task, no autoscaling)
├── prod.tfvars             # Prod values (2 tasks, CPU autoscaling 2–10)
├── terraform.tfvars.example
└── modules/
    ├── networking/         # VPC, 2 public subnets, IGW
    └── ecs/                # Cluster, ALB, Fargate ARM64, logs, autoscaling
```

## Key resources (all prefixed `fastapi-translation`)

| Resource | Terraform | Purpose |
|----------|-----------|---------|
| ECR repo | `aws_ecr_repository.app` | Stores `fastapi-translation` Docker images |
| ECS cluster | `module.ecs` | `fastapi-translation-cluster` |
| ECS service | `module.ecs` | `fastapi-translation-service` |
| Task definition | `module.ecs` | Container name = `fastapi-translation`, port **3000**, **ARM64** |
| ALB | `module.ecs` | Public HTTP → tasks |
| Log group | `module.ecs` | `/ecs/fastapi-translation` |

## Variables (terraform.tfvars)

| Variable | Dev | Prod |
|----------|-----|------|
| `desired_count` | 1 | 2 |
| `enable_autoscaling` | false | true |
| `autoscaling_min_capacity` | — | 2 |
| `autoscaling_max_capacity` | — | 10 |
| `task_cpu` / `task_memory` | 2048 / 4096 | same (ML models need RAM) |

## Outputs (used by scripts)

| Output | Used for |
|--------|----------|
| `ecr_uri` | `deploy-image.sh` push target |
| `api_url` | `test-api.sh`, browser |
| `ecs_cluster_name` | `deploy.sh`, `status.sh` |
| `ecs_service_name` | `deploy.sh`, `redeploy-app.sh` |

## Workflow commands

Always use the profile:

```bash
export AWS_PROFILE=terraform-user
export AWS_PAGER=""
```

| Action | Command |
|--------|---------|
| Init | `cd infra && terraform init` |
| Plan only | `./scripts/plan.sh dev` |
| Plan + apply + image + ECS | `./scripts/deploy.sh dev` |
| Destroy | `./scripts/destroy.sh dev` |

## What to run after changes

| You changed | Run |
|-------------|-----|
| `main.py`, `Dockerfile`, `templates/`, `requirements-docker.txt` | `./scripts/redeploy-app.sh dev` |
| `infra/*.tf`, `terraform.tfvars`, `prod.tfvars` | `./scripts/plan.sh dev` then `./scripts/deploy.sh dev` |

## Plan before apply

`deploy.sh` always runs **`terraform plan`** first and asks for **`yes`** before apply. Never skip plan for infra changes.

## State files

- State is stored locally in `infra/terraform.tfstate` (gitignored).
- For teams, configure a remote backend (S3 + DynamoDB) in `main.tf` later.

## Apple Silicon → ECS ARM64

- Local build for ECS: `linux/arm64` (`deploy-image.sh`)
- Task definition: `cpu_architecture = "ARM64"`
- Install Terraform: **darwin_arm64** build

## Security notes

- ALB allows HTTP :80 from the internet (add HTTPS + ACM in a follow-up).
- ECS tasks only accept traffic on port 3000 from the ALB security group.
- Do not commit `.env`, `terraform.tfstate`, or AWS keys.
