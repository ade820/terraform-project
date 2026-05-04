# VaultBridge Terraform Project

## Infrastructure Philosophy

> "All VaultBridge infrastructure must be defined in Terraform code and managed
> through a version-controlled workflow. No infrastructure resource should exist
> that is not represented in the codebase. The answer to 'what does our AWS
> environment look like?' is: **read the Terraform files**."

This repository is the single source of truth for VaultBridge Financial
Technologies' cloud infrastructure. Every resource — network, compute,
database, and security — is defined in code, version controlled, peer
reviewed, and fully auditable.

---

## Project Overview

**Company:** VaultBridge Financial Technologies
**Industry:** Banking / Fintech
**Programme:** Infrastructure Modernisation 
**Region:** AWS eu-west-1 (Ireland)
**Start Date:** April 20, 2026

This project transitions VaultBridge from manually managed cloud
infrastructure to Infrastructure as Code (IaC) using Terraform, directly
addressing the root causes of the November 2023 production incident that
caused a 4-hour outage and $214,000 in losses.

---

## Repository Structure
terraform-project/
├── bootstrap/                    # One-time remote state setup
│   ├── main.tf                   # S3 bucket + DynamoDB table
│   └── outputs.tf                # Bucket name and table name outputs
│
├── infra/                        # Main infrastructure workspace
│   ├── backend.tf                # S3 remote state configuration
│   ├── providers.tf              # AWS provider + version constraints
│   ├── variables.tf              # Input variable declarations
│   ├── terraform.tfvars          # Actual values (GITIGNORED — never commit)
│   ├── vpc.tf                    # VPC, subnets, IGW, route tables
│   ├── security_groups.tf        # EC2 and RDS firewall rules
│   ├── ec2.tf                    # Application server + Elastic IP
│   ├── rds.tf                    # PostgreSQL database + subnet group
│   └── outputs.tf                # EC2 IP, RDS endpoint, VPC ID
│
├── .gitignore                    # Excludes state files, tfvars, tfplan
└── README.md                     # This file


---

## Architecture
                    INTERNET
                        │
                Internet Gateway
                        │
        ┌───────────────┴───────────────┐
        │           PUBLIC TIER          │
        │  public_1: 10.0.1.0/24 (1a)   │
        │  public_2: 10.0.2.0/24 (1b)   │
        │                               │
        │  ┌─────────────────────────┐  │
        │  │  EC2 t3.micro           │  │
        │  │  Amazon Linux 2023      │  │
        │  │  Elastic IP assigned    │  │
        │  │  SSH: engineer IP only  │  │
        │  └────────────┬────────────┘  │
        └───────────────┼───────────────┘
                        │ port 5432 only
                        │ (SG reference)
        ┌───────────────┴───────────────┐
        │          PRIVATE TIER          │
        │  private_1: 10.0.3.0/24 (1a)  │
        │  private_2: 10.0.4.0/24 (1b)  │
        │                               │
        │  ┌─────────────────────────┐  │
        │  │  RDS PostgreSQL 15.17   │  │
        │  │  db.t3.micro — 20GB gp3 │  │
        │  │  Encrypted at rest      │  │
        │  │  NOT publicly accessible│  │
        │  └─────────────────────────┘  │
        └───────────────────────────────┘
                No internet route

---

## Infrastructure Components

### State Management (bootstrap/)
| Resource | Name | Purpose |
|---|---|---|
| S3 Bucket | `vaultbridge-terraform-state-*` | Remote state storage |
| S3 Versioning | Enabled | State history and recovery |
| S3 Encryption | AES256 | State file security |
| DynamoDB Table | `vaultbridge-terraform-locks` | Concurrent apply prevention |

### Networking (vpc.tf)
| Resource | CIDR | AZ | Purpose |
|---|---|---|---|
| VPC | `10.0.0.0/16` | — | Network boundary |
| public_1 | `10.0.1.0/24` | eu-west-1a | EC2 application server |
| public_2 | `10.0.2.0/24` | eu-west-1b | High availability |
| private_1 | `10.0.3.0/24` | eu-west-1a | RDS database |
| private_2 | `10.0.4.0/24` | eu-west-1b | RDS subnet group |

### Security (security_groups.tf)
| Group | Port | Source | Reason |
|---|---|---|---|
| EC2 SG | 22 | Engineer IP /32 | SSH — restricted, never 0.0.0.0/0 |
| EC2 SG | 80 | 0.0.0.0/0 | HTTP application traffic |
| EC2 SG | 443 | 0.0.0.0/0 | HTTPS application traffic |
| RDS SG | 5432 | EC2 SG ID | PostgreSQL — SG reference only |

### Compute (ec2.tf)
| Resource | Value |
|---|---|
| AMI | Amazon Linux 2023 (latest) |
| Instance type | t3.micro |
| Root volume | 30GB gp3 — encrypted |
| User data | yum update + postgresql15 client |
| Elastic IP | Static public IP |

### Database (rds.tf)
| Resource | Value |
|---|---|
| Engine | PostgreSQL 15.17 |
| Instance type | db.t3.micro |
| Storage | 20GB gp3 — encrypted |
| Publicly accessible | false |
| Parameter group | log_connections, log_disconnections, slow query |

---

## The Deployment Workflow

Every infrastructure change follows this 7-step workflow without exception:

```bash
# 1. Format — enforces consistent style
terraform fmt -recursive

# 2. Validate — catches syntax errors before any API calls
terraform validate

# 3. Plan — generates human-readable preview (the audit record)
terraform plan -out=tfplan

# 4. Review — peer code review of plan output (required)
# A second engineer confirms the plan matches intent

# 5. Apply — executes the reviewed plan only
terraform apply tfplan

# 6. Verify — confirm outputs and test resources
terraform output

# 7. Commit — creates the permanent audit record
git add . && git commit -m "Descriptive message"
```

---

## Security Principles

**Principle of Least Privilege**
Every security group rule grants the minimum access required. SSH is
restricted to a specific engineer IP. Database access is granted only
to the EC2 security group — not to a CIDR range.

**Defence in Depth**
The RDS instance is protected by two independent controls:
1. Security group: port 5432 allows EC2 SG only
2. Network: private subnet has no internet gateway route

Both controls must fail simultaneously for the database to be exposed.
This is the architectural answer to the November 2023 incident.

**Encryption Everywhere**
- EC2 root volume: encrypted (KMS managed)
- RDS storage: encrypted at rest
- RDS connections: SSL enforced (TLSv1.2)
- Terraform state: AES256 encrypted in S3

**No Manual Console Changes**
Zero infrastructure changes are made through the AWS Console.
Every change is code, reviewed, planned, applied, and committed.

---

## Business Objectives Addressed

| Objective | How This Repository Addresses It |
|---|---|
| Eliminate uncontrolled manual changes | All resources in `.tf` files — no console changes |
| Establish recoverable shared state | S3 remote state + DynamoDB locking |
| Enforce network isolation by architecture | RDS in private subnet — no internet route |
| Produce compliant auditable record | Git history + Terraform plans = CBN audit trail |
| Enable environment parity | Same code + different tfvars = identical environments |

---

## How to Use This Repository

### Prerequisites
- Terraform >= 1.5
- AWS CLI v2 configured
- Git

### First-time setup (bootstrap)
```bash
cd bootstrap
terraform init
terraform plan -out=tfplan
terraform apply tfplan
# Note the S3 bucket name from outputs
```

### Deploy infrastructure
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars  # fill in your values
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Connect to EC2
```bash
ssh -i ~/.ssh/id_rsa ec2-user@$(terraform output -raw ec2_public_ip)
```

### Connect to RDS (from inside EC2)
```bash
psql -h $(terraform output -raw rds_endpoint) -U vaultbridge_admin -d vaultbridge
```

### Destroy infrastructure
```bash
cd infra
terraform destroy
```

---

## Important: Never Commit These Files
terraform.tfvars      # Contains credentials and IP addresses
*.tfstate             # Contains sensitive infrastructure state
*.tfstate.backup      # State backup files
.terraform/           # Provider plugins (auto-downloaded)
tfplan                # Binary plan files

These are all excluded by `.gitignore`.

---

## Audit Trail

Every infrastructure change in this repository is traceable to:
- A Git commit (who, when, what changed)
- A Terraform plan output (what AWS will do)
- An S3 state version (what AWS actually did)

This satisfies the Central Bank of Nigeria's Change Management audit
requirements for Payment Service Providers without any additional
documentation effort.

---

*VaultBridge Infrastructure Modernisation Programme — April/May 2026*
*Built by: Infrastructure Engineering Intern*
*Supervisor: Programme Supervisor*
