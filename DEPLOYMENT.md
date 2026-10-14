# Tourvisor Deployment Guide

This document outlines the deployment options for **Tourvisor** across containerized environments, Kubernetes clusters, and cloud infrastructure.

---

## 1. Quick Start with Docker Compose (Local / Single Host)

### Prerequisites:
- Docker Engine 24+ and Docker Compose v2

### Steps:
1. Copy `.env.example` to `bc-cms/.env` (or let the entrypoint auto-generate it):
   ```bash
   cp bc-cms/.env.example bc-cms/.env
   ```

2. Start all services:
   ```bash
   docker compose up -d --build
   ```

3. Access the services:
   - **Tourvisor Web Application:** [http://localhost:8080](http://localhost:8080)
   - **Local Email Testing (Mailpit):** [http://localhost:8025](http://localhost:8025)
   - **MySQL Database:** `localhost:3306` (User: `tourvisor_user`, Pass: `secret_password`)
   - **Redis Cache:** `localhost:6379`

4. Run migrations or initial installer:
   ```bash
   docker compose exec app php /var/www/html/bc-cms/artisan migrate --seed
   ```

5. View real-time logs:
   ```bash
   docker compose logs -f app
   ```

---

## 2. Kubernetes Deployment with Helm Chart

The production Helm chart is located under [`deploy/helm/tourvisor/`](deploy/helm/tourvisor/).

### Architecture:
- **App Pods:** Multi-replica PHP-FPM application with Nginx sidecar.
- **Queue Workers:** Dedicated deployment running `php artisan queue:work`.
- **Cron Scheduler:** Native Kubernetes `CronJob` running `schedule:run` every minute.
- **Autoscaling:** Horizontal Pod Autoscaler (HPA) targeting CPU & Memory.
- **Persistent Storage:** PVCs for `uploads/` and `storage/`.

### Deployment Steps:
1. Package and test the chart:
   ```bash
   helm lint deploy/helm/tourvisor
   ```

2. Install or upgrade release:
   ```bash
   helm upgrade --install tourvisor ./deploy/helm/tourvisor \
     --namespace tourvisor \
     --create-namespace \
     --set secrets.dbPassword="YourSecureDBPassword" \
     --set secrets.appKey="base64:QxLhDm6tg22cy6QcijKCXCYF4fDO3kptPjQSscp9Cs8=" \
     --set ingress.hosts[0].host="tourvisor.yourdomain.com"
   ```

---

## 3. Cloud Infrastructure with Terraform (AWS)

Located under [`deploy/terraform/`](deploy/terraform/). Provisions:
- Highly available VPC with public, private, and database subnets across 2 AZs.
- Amazon EKS Cluster + Managed Node Groups.
- Amazon RDS (MySQL 8.0 Multi-AZ option).
- Amazon ElastiCache (Redis 7).
- Amazon S3 bucket for media storage.

### Deployment Steps:
1. Navigate to Terraform directory:
   ```bash
   cd deploy/terraform
   ```

2. Initialize and plan:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your credentials
   terraform init
   terraform plan
   ```

3. Apply infrastructure:
   ```bash
   terraform apply
   ```

---

## 4. Automated VPS Deployment with Ansible

Located under [`deploy/ansible/`](deploy/ansible/). Automates setting up Docker, Docker Compose, Git repository cloning, configuration, and starting the containers on any Ubuntu/Debian server.

### Run Playbook:
```bash
cd deploy/ansible
cp inventory.ini.example inventory.ini
# Edit inventory.ini with target server IP and SSH key
ansible-playbook -i inventory.ini playbook.yml
```
