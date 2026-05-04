# Written Reflection
## VaultBridge Infrastructure Modernisation Programme
**Author:** Elias Adeleke 
**Date:** May 2026

---

## 1. What Each File Does and Why It Is Separate

### `bootstrap/main.tf`
Creates the S3 bucket and DynamoDB table that store Terraform state.
This is a separate workspace because of the bootstrap problem: you cannot
store state in an S3 bucket that Terraform itself is creating. It runs
once with local state, then all subsequent work uses the remote backend
it created.

### `infra/backend.tf`
Tells Terraform where to store state — the S3 bucket created in bootstrap.
It is separate from providers.tf because backend configuration initialises
before providers do. Keeping it isolated makes it easy to change the
backend without touching provider logic.

### `infra/providers.tf`
Declares the AWS provider and Terraform version constraints. Separated
from backend.tf so that provider configuration (region, version pinning)
can be updated independently of state configuration.

### `infra/variables.tf`
Declares all input variables with descriptions and types. Contains no
values, only declarations. This separation means the same infrastructure
code can be reused for dev, staging, and production by changing only
terraform.tfvars, never the core logic.

### `infra/terraform.tfvars`
Contains the actual values for variables such as IP address, credentials, region.
Gitignored deliberately. Sensitive values never enter version control.
This is the only file that differs between environments.

### `infra/vpc.tf`
Defines the network foundation: VPC, subnets, internet gateway, route
tables. Separated because networking is the lowest layer and everything
else depends on it. Keeping it isolated means network changes can be
reviewed without touching compute or database logic.

### `infra/security_groups.tf`
Defines firewall rules for EC2 and RDS. Separated from vpc.tf because
security rules change more frequently than network topology. A separate
file makes security reviews faster and peer review more focused.

### `infra/ec2.tf`
Defines the application server: AMI lookup, key pair, instance, Elastic
IP. Separated because compute resources have a different lifecycle to
networking, instances get replaced, AMIs get updated, IPs get reassigned.

### `infra/rds.tf`
Defines the database: subnet group, parameter group, RDS instance.
Separated because the database is the most sensitive resource and warrants
its own review cycle. Database changes in production require a separate
approval process from compute changes.

### `infra/outputs.tf`
Prints useful values after apply: EC2 IP, RDS endpoint, VPC ID. Separated
so that output definitions do not clutter resource files and can be updated
independently.

---

## 2. How My Implementation Addresses the Root Causes

### Root Cause 1: No infrastructure record
**Solution:** Every resource is defined in `.tf` files committed to Git.
The answer to "what does our environment look like?" is now "read the
Terraform files." No mental models, no Confluence pages that go stale.

### Root Cause 2: Changes bypassed quality controls
**Solution:** The 7-step workflow (fmt → validate → plan → review → apply
→ verify → commit) enforces peer review before any change reaches AWS.
A security group change that previously took one console click now requires
a pull request, a plan review, and a second engineer's approval.

### Root Cause 3: Environment drift
**Solution:** The same codebase with different `terraform.tfvars` produces
identical environments. Configuration drift is structurally impossible
because environments are not built by hand — they are generated from code.

### Root Cause 4: Disaster recovery was theoretical
**Solution:** Rebuilding the entire VaultBridge infrastructure now requires
two commands: `terraform init` and `terraform apply`. Any engineer on the
team can execute it. The November 2023 recovery took 4 hours because only
one engineer knew the configuration from memory. That single point of
failure no longer exists.

### Root Cause 5: Compliance exposure
**Solution:** Every infrastructure change produces a Terraform plan output
(the audit record), a Git commit (the timestamp and author), and an updated
S3 state file (the machine-readable record). This satisfies the CBN Change
Management audit requirement without any additional documentation effort.

---

cat >> REFLECTION.md << 'EOF'

---
## 3. One Thing I Would Change With More Time

I would refactor the infrastructure into **reusable Terraform modules**.

### The Current Problem

All resources are currently defined in flat `.tf` files inside a single
`infra/` directory. This works for one environment but creates a
structural drift risk when scaling to multiple environments.

To create a staging environment today, I would need to either:

- **Option A:** Duplicate the entire `infra/` directory and manually
  adjust variable values. Now two copies of the same logic exist. When
  the networking configuration changes in dev, someone must remember to
  apply the same change in staging manually and this is exactly the
  environment drift that caused 23 of VaultBridge's deployment failures.

- **Option B:** Use the same workspace with different tfvars. This
  prevents drift but means dev and staging share state which means a single
  `terraform destroy` could wipe both environments simultaneously.

Both options reintroduce the risk we set out to eliminate.

### The Module Solution

Modules solve drift structurally rather than procedurally:
modules/
├── networking/    — VPC, subnets, IGW, route tables
├── compute/       — EC2, key pair, Elastic IP
└── database/      — RDS, subnet group, parameter group
environments/
├── dev/
│   ├── main.tf    — calls modules with dev variable values
│   └── terraform.tfvars
└── staging/
├── main.tf    — calls SAME modules with staging variable values
└── terraform.tfvars

When `environments/dev/main.tf` and `environments/staging/main.tf` both
call `module "networking"` from the same source, they are guaranteed to
produce structurally identical network configurations. A change to the
module — for example, adding a third private subnet. This is applied to both
environments on the next `terraform apply`. It is impossible for one
environment to have a configuration that the other does not, because they
share a single source file.

### Why This Matters for VaultBridge

The November 2023 incident and the 23 deployment failures both had the
same underlying cause: configuration existed in some environments that did
not exist in others. The staging environment had different database
parameter settings and instance types than production because they were
built at different times by different engineers.

Modules make environment parity a structural guarantee rather than a
process requirement. Process requirements fail under time pressure.
Structural guarantees do not.

### What This Would Require

- Refactor `vpc.tf`, `ec2.tf`, and `rds.tf` into module directories
- Create `environments/dev/` and `environments/staging/` workspaces
- Each environment gets its own remote state key in S3:
  - `envs/dev/terraform.tfstate`
  - `envs/staging/terraform.tfstate`
- Variable values differ per environment (instance size, CIDR ranges)
- Module source code is shared — one change propagates everywhere

This is the natural next step for this codebase and would be the first
task if the programme continued.
