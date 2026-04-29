# ─────────────────────────────────────────────
# DB Subnet Group
# ─────────────────────────────────────────────
# Tells RDS which subnets it can use
# Must span at least 2 AZs — AWS hard requirement
# We use PRIVATE subnets — database never exposed to internet
resource "aws_db_subnet_group" "main" {
  name        = "vaultbridge-db-subnet-group"
  description = "Private subnet group for VaultBridge RDS instance"
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name        = "vaultbridge-db-subnet-group"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────
# DB Parameter Group
# ─────────────────────────────────────────────
# Custom PostgreSQL configuration parameters
# Allows tuning database behaviour without modifying
# the instance — changes applied at the parameter level
resource "aws_db_parameter_group" "postgres15" {
  name        = "vaultbridge-postgres15-params"
  family      = "postgres15"
  description = "Custom parameter group for VaultBridge PostgreSQL 15"

  # Log all connection attempts — important for audit trail
  # Directly addresses VaultBridge compliance requirements
  parameter {
    name  = "log_connections"
    value = "1"
  }

  # Log all disconnections with session duration
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  # Log queries that take longer than 1 second
  # Helps identify performance issues early
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name        = "vaultbridge-postgres15-params"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────
# RDS PostgreSQL Instance
# ─────────────────────────────────────────────
resource "aws_db_instance" "postgres" {
  # ── Identity ──────────────────────────────
  identifier = "vaultbridge-postgres"
  db_name    = "vaultbridge"

  # ── Engine ────────────────────────────────
  engine         = "postgres"
  engine_version = "15.17"

  # ── Instance Size ─────────────────────────
  instance_class = "db.t3.micro"

  # ── Storage ───────────────────────────────
  storage_type      = "gp3"
  allocated_storage = 20
  storage_encrypted = true

  # ── Credentials ───────────────────────────
  # Sourced from variables — NEVER hardcoded
  # Values come from terraform.tfvars (gitignored)
  username = var.db_username
  password = var.db_password

  # ── Network ───────────────────────────────
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # CRITICAL: false means database is NOT reachable from internet
  # Even if security group were misconfigured, this adds another layer
  publicly_accessible = false

  # ── Parameter Group ───────────────────────
  parameter_group_name = aws_db_parameter_group.postgres15.name

  # ── Availability ──────────────────────────
  # Single AZ for dev — production would use multi_az = true
  multi_az          = false
  availability_zone = "${var.aws_region}a"

  # ── Backup ────────────────────────────────
  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # ── Monitoring ────────────────────────────
  monitoring_interval = 0

  # ── Deletion ──────────────────────────────
  # skip_final_snapshot = true for this exercise only
  # Production MUST set this to false and define final_snapshot_identifier
  skip_final_snapshot      = true
  delete_automated_backups = true
  deletion_protection      = false

  tags = {
    Name        = "vaultbridge-postgres"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}
