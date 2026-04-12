# Tetris on AWS

> A fully automated infrastructure deployment of a browser-based Tetris game on AWS EC2, provisioned with Terraform and deployed via GitHub Actions CI/CD pipeline.

---

## Overview

This project demonstrates end-to-end Infrastructure as Code (IaC) and CI/CD automation. Every `git push` to `main` provisions or updates a live AWS environment — no manual console clicks required.

The game itself is [jakesgordon/javascript-tetris](https://github.com/jakesgordon/javascript-tetris), served via Nginx on an EC2 instance bootstrapped entirely through a `userdata.sh` script.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS (ap-south-1)                     │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │              VPC (10.0.0.0/16)                  │   │
│   │                                                 │   │
│   │   ┌──────────────────────────────────────────┐  │   │
│   │   │         Public Subnet (10.0.1.0/24)      │  │   │
│   │   │                                          │  │   │
│   │   │   ┌───────────────────────────────────┐  │  │   │
│   │   │   │  Security Group                   │  │  │   │
│   │   │   │  Inbound:  port 80  (HTTP)        │  │  │   │
│   │   │   │  Outbound: all ports              │  │  │   │
│   │   │   │                                   │  │  │   │
│   │   │   │  ┌────────────────────────────┐   │  │  │   │
│   │   │   │  │   EC2 t3.micro (Ubuntu)    │   │  │  │   │
│   │   │   │  │   Nginx → Tetris game      │   │  │  │   │
│   │   │   │  └────────────────────────────┘   │  │  │   │
│   │   │   └───────────────────────────────────┘  │  │   │
│   │   └──────────────────────────────────────────┘  │   │
│   │                        │                        │   │
│   │             Internet Gateway                    │   │
│   └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                             │
                        Public Internet
                             │
                         Browser
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Cloud provider | AWS (ap-south-1 / Mumbai) |
| Compute | EC2 t3.micro — Ubuntu 22.04 LTS |
| Web server | Nginx |
| Networking | VPC, Subnet, Internet Gateway, Route Table |
| Firewall | Security Group (port 80 inbound, all outbound) |
| Infrastructure as Code | Terraform |
| CI/CD | GitHub Actions |
| Game | [tetris](https://github.com/jakesgordon/javascript-tetris) |

---

## Repository Structure

```
tetris-on-aws/
├── terraform/
│   ├── main.tf          # AWS resource definitions (VPC, EC2, SG, etc.)
│   ├── outputs.tf       # Prints the server URL after deployment
│   └── userdata.sh      # EC2 bootstrap script — installs Nginx, clones game
├── .github/
│   └── workflows/
│       └── deploy.yml   # GitHub Actions pipeline
├── .gitignore
└── README.md
```

---

## How It Works

### Deployment flow

```
git push origin main
        │
        ▼
GitHub Actions triggers deploy.yml
        │
        ├── Configure AWS credentials (from GitHub Secrets)
        ├── terraform init   (downloads AWS provider)
        └── terraform apply  (creates all AWS resources)
                │
                ▼
        EC2 instance launches
                │
                ▼
        userdata.sh runs on first boot
                │
                ├── apt-get install nginx git
                ├── git clone javascript-tetris → /var/www/html
                └── systemctl start nginx
                        │
                        ▼
                http://<public-ip>  →  Tetris loads
```

### Infrastructure provisioned by Terraform

- **VPC** — isolated private network (`10.0.0.0/16`)
- **Public Subnet** — subnet with public IP assignment (`10.0.1.0/24`, `ap-south-1a`)
- **Internet Gateway** — connects the VPC to the public internet
- **Route Table** — routes all outbound traffic (`0.0.0.0/0`) through the gateway
- **Security Group** — allows inbound HTTP (port 80) and all outbound traffic
- **EC2 Instance** — `t3.micro` Ubuntu server with Nginx serving the game

---

## Getting Started

### Prerequisites

- AWS account (free tier eligible)
- GitHub account
- Terraform installed locally (for optional local runs)
- AWS CLI configured (for optional local runs)

### 1. Fork or clone this repo

```bash
git clone https://github.com/DikshaGanchaudhuri/Tetris-terraform.git
cd Tetris-terraform
```

### 2. Add AWS credentials to GitHub Secrets

In your repo: **Settings → Secrets and variables → Actions**

| Secret name | Value |
|---|---|
| `AWS_ACCESS_KEY` | Your IAM user Access Key ID |
| `AWS_SECRET_KEY` | Your IAM user Secret Access Key |

> Create an IAM user with `AdministratorAccess` in AWS Console → IAM → Users → Security credentials → Create access key.

### 3. Push to deploy

```bash
git push origin main
```

GitHub Actions will run automatically. Monitor progress under the **Actions** tab.

### 4. Get your URL

In the Actions run → **Terraform Apply** step → scroll to bottom:

```
Outputs:

website_url = "http://<your-public-ip>"
```

Open it in a browser. Wait ~2 minutes after the pipeline finishes for Nginx to fully start.

---

## Destroying Infrastructure

To avoid ongoing AWS charges, destroy the infrastructure when not in use.

**Option 1 — AWS Console**
- EC2 → terminate the `Tetris-Server` instance
- VPC → delete the VPC with CIDR `10.0.0.0/16`

**Option 2 — Terraform CLI**
```bash
cd terraform
terraform init
terraform destroy -auto-approve
```

---

## Security Notes

- The IAM user used here has `AdministratorAccess` — acceptable for learning, but scope it down for production use
- AWS credentials are stored in GitHub Secrets and never appear in code or logs
- The `terraform.tfstate` file is excluded from version control via `.gitignore` — never commit it
- The `.terraform/` directory (provider binaries) is also excluded — it's auto-downloaded on `terraform init`
- Port 22 (SSH) is intentionally closed — all server configuration happens through `userdata.sh`

---

## Learning Outcome

This project covers foundational DevOps concepts:

- **Infrastructure as Code** — describing cloud resources in declarative config files instead of clicking through a console
- **CI/CD pipelines** — automating deployment on every code push using GitHub Actions
- **AWS networking** — VPC, subnets, internet gateways, route tables, and security groups
- **EC2 bootstrapping** — using `userdata.sh` to configure a server automatically on first boot
- **Debugging cloud deployments** — region/AMI mismatches, missing egress rules, wrong package managers, git history hygiene