# Starterkit v3 deployment commands (Docker + GHCR)

## 1) Infra create (one-time or infra change only)
```powershell
cd d:\infrastructure\learning\v3-starterkit
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
terraform output elastic_ip
terraform output app_endpoint
```

## 2) Rollback (destroy infra)
```powershell
powershell -ExecutionPolicy Bypass -File .\rollback.ps1 -AutoApprove
```

## 3) Deploy/update app without Terraform
```bash
sudo /usr/local/bin/starterkit-docker-deploy.sh
sudo docker ps
sudo docker logs --tail=100 starterkit-app
```

## 4) Useful logs on EC2
```bash
tail -f /var/log/cloud-init-output.log
sudo docker logs -f starterkit-app
```

## 5) Required GitHub token permissions for GHCR pull
- `read:packages` (required)
- `repo` (required only if package is private and tied to private repo visibility)

## 6) GitHub Actions deploy trigger (no cron)
- Use the provided workflow template: `github-actions-staging-ghcr.yml`.
- Trigger: push/merge into `staging`.
- Flow: build image -> push to GHCR -> call AWS SSM Run Command on EC2 -> run `/usr/local/bin/starterkit-docker-deploy.sh`.
- Required repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (example: `ap-south-1`)
- `EC2_INSTANCE_ID` (from `terraform output ec2_instance_id`)

## 7) SSM access (no SSH key needed)
```powershell
aws ssm start-session --target <ec2_instance_id> --region ap-south-1
```
- Your EC2 role now includes `AmazonSSMManagedInstanceCore`.
- Your IAM user/role running this command must also have SSM permissions.

## 8) Suggested app image model
- Image: `ghcr.io/<owner>/<repo>:staging`
- Every merge to `staging` builds and pushes new image to GHCR.
- GitHub Action deploy job pulls latest `staging` image and restarts container on EC2.
