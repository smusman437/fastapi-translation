# fastapi-translation

English → Turkish translator API built with **FastAPI** and Hugging Face models (`ckartal/english-to-turkish-finetuned-model`).

## App identity (Docker & AWS)

All resources use the name **`fastapi-translation`** so you can trace what runs where:

| Environment | Image | Container / service |
|-------------|-------|---------------------|
| Local Docker | `fastapi-translation:local` | `fastapi-translation-app` |
| AWS ECR | `{account}.dkr.ecr.../fastapi-translation:latest` | ECS container `fastapi-translation` |
| AWS ECS | — | cluster `fastapi-translation-cluster`, service `fastapi-translation-service` |

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Web UI |
| `/health` | Health check (`{"status":"ok","app":"fastapi-translation"}`) |
| `/apidocs` | Swagger UI |
| `POST /translate/` | Translate JSON `{"text":"..."}` |
| `POST /translate-and-speak/` | Translate + WAV audio |

## Quick start (local Docker)

```bash
chmod +x scripts/*.sh scripts/lib/common.sh
./scripts/local.sh
./scripts/test-api.sh http://localhost:3000
```

Stop: `./scripts/stop-local.sh`

First boot downloads models into `.cache/huggingface` (several minutes).

## AWS ECS deploy (Terraform)

**Docs:** [GUIDE.md](./GUIDE.md) · [TERRAFORM.md](./TERRAFORM.md) · [PROD.md](./PROD.md)

```bash
cp .env.example .env
export AWS_PROFILE=terraform-user
aws configure --profile terraform-user

./scripts/plan.sh dev
./scripts/deploy.sh dev    # plan → yes → apply → push image → ECS
./scripts/status.sh
```

| Goal | Command |
|------|---------|
| Local | `./scripts/local.sh` |
| Preview infra | `./scripts/plan.sh dev` |
| Full deploy | `./scripts/deploy.sh dev` |
| App code only | `./scripts/redeploy-app.sh dev` |
| Prod | `./scripts/deploy.sh prod` |
| Destroy | `./scripts/destroy.sh dev` |

**Detected config:** project `fastapi-translation`, port **3000**, health **`/health`**, **Python/FastAPI**, **ARM64** Fargate.

## Local Python (without Docker)

```bash
pip install -r requirements-docker.txt
pip install torch --index-url https://download.pytorch.org/whl/cpu
uvicorn main:app --host 0.0.0.0 --port 3000
```

## Vercel

Lightweight `index.py` (HTTP translation API) is deployed via `vercel.json` — separate from the Docker/ECS ML stack in `main.py`.
