# PROD.md — fastapi-translation production checklist

Prod uses `infra/prod.tfvars`:

- **2** ECS tasks minimum
- CPU autoscaling **2–10** tasks
- Same app image: `fastapi-translation` on port **3000**

## Before prod deploy

- [ ] `export AWS_PROFILE=terraform-user`
- [ ] `aws sts get-caller-identity --profile terraform-user`
- [ ] Terraform installed (darwin_arm64 on Mac)
- [ ] Dev deploy succeeded: `./scripts/deploy.sh dev`
- [ ] `./scripts/test-api.sh` passed against dev ALB URL

## Deploy prod

```bash
./scripts/plan.sh prod
# Review: 2 tasks, autoscaling enabled, fastapi-translation names

./scripts/deploy.sh prod
# Type yes when prompted

./scripts/status.sh
./scripts/test-api.sh "$(cd infra && terraform output -raw api_url)"
```

## URLs to verify

| Check | URL |
|-------|-----|
| Health | `{api_url}/health` → `"app":"fastapi-translation"` |
| UI | `{api_url}/` |
| Swagger | `{api_url}/apidocs` |
| Translate | `POST {api_url}/translate/` |

## App-only release (prod)

```bash
./scripts/redeploy-app.sh prod
```

## Rollback

Push a known-good image tag to ECR, update `image_tag` in `prod.tfvars`, then:

```bash
./scripts/deploy.sh prod
```

Or redeploy previous image digest via AWS Console → ECS → Update service.

## Cost awareness

- Fargate 2 vCPU / 4 GB × 2 tasks runs continuously
- Autoscaling can grow to 10 tasks under load
- Hugging Face model download on **each new task** (use EFS for shared cache in a future iteration)

## Destroy prod

```bash
./scripts/destroy.sh prod
```
