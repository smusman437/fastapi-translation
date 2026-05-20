# GUIDE: fastapi-translation — Local Docker → AWS ECS

This guide walks through deploying the **fastapi-translation** app (English → Turkish API) from your laptop to AWS ECS Fargate.

## What runs where (naming map)

| Layer | Name | What it is |
|--------|------|------------|
| **Project / ECR repo** | `fastapi-translation` | Git repo and AWS ECR repository name |
| **Local Docker image** | `fastapi-translation:local` | Image built on your Mac |
| **Local container** | `fastapi-translation-app` | Running container on port **3000** |
| **ECS cluster** | `fastapi-translation-cluster` | Fargate cluster |
| **ECS service** | `fastapi-translation-service` | Keeps tasks running behind the ALB |
| **ECS container** | `fastapi-translation` | Same name inside the task definition |
| **CloudWatch logs** | `/ecs/fastapi-translation` | Container stdout/stderr |
| **ALB** | `fastapi-translation-alb` | Public HTTP entry point |

Every script prints this banner so you always know which app you are deploying.

---

## Phase 1 — Local Docker

**Prerequisites:** Docker Desktop

```bash
export AWS_PROFILE=terraform-user   # only needed later; optional now
chmod +x scripts/*.sh scripts/lib/common.sh
./scripts/local.sh
```

| URL | Purpose |
|-----|---------|
| http://localhost:3000/ | Web UI |
| http://localhost:3000/health | Health JSON (`"app": "fastapi-translation"`) |
| http://localhost:3000/apidocs | Swagger UI |

```bash
./scripts/test-api.sh
./scripts/stop-local.sh
```

**Note:** First start downloads Hugging Face models (~several minutes). Models are cached in `.cache/huggingface`.

---

## Phase 2 — AWS CLI profile

Use a dedicated profile (not default) for Terraform:

```bash
aws configure --profile terraform-user
export AWS_PROFILE=terraform-user
export AWS_PAGER=""
aws sts get-caller-identity --profile terraform-user
```

IAM user needs permissions for VPC, ECS, ECR, ALB, CloudWatch, IAM roles, and autoscaling.

---

## Phase 3 — Terraform (infrastructure only)

**Prerequisites:** [Terraform](https://developer.hashicorp.com/terraform/install) — on Apple Silicon use **darwin_arm64**.

```bash
cd infra
terraform init
cd ..
./scripts/plan.sh dev      # review only
```

Infra creates VPC, ECR, ALB, ECS cluster/service — **no app image yet** until deploy.

See [TERRAFORM.md](./TERRAFORM.md) for file-by-file details.

---

## Phase 4 — First deploy to ECS

```bash
./scripts/deploy.sh dev
```

This will:

1. `terraform plan` → you type **`yes`**
2. `terraform apply` (ECR, VPC, ALB, ECS)
3. Build **linux/arm64** image and push to ECR
4. `ecs update-service --force-new-deployment` and wait until healthy

```bash
./scripts/status.sh
./scripts/test-api.sh "$(cd infra && terraform output -raw api_url)"
```

---

## Phase 5 — App updates (no infra change)

Changed `main.py`, `Dockerfile`, or `templates/` only:

```bash
./scripts/redeploy-app.sh dev
```

---

## Phase 6 — Production

```bash
./scripts/plan.sh prod
./scripts/deploy.sh prod
```

See [PROD.md](./PROD.md) for the prod checklist.

---

## Phase 7 — Destroy

```bash
./scripts/destroy.sh dev
```

Force-deletes ECR images, then `terraform destroy`.

---

## Quick command reference

| Goal | Command |
|------|---------|
| Run locally | `./scripts/local.sh` |
| Preview infra | `./scripts/plan.sh dev` |
| First / infra deploy | `./scripts/deploy.sh dev` |
| App code only | `./scripts/redeploy-app.sh dev` |
| ECS status | `./scripts/status.sh` |
| Smoke test | `./scripts/test-api.sh <url>` |
| Tear down | `./scripts/destroy.sh dev` |
