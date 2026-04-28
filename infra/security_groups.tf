# ─────────────────────────────────────────────
# EC2 Security Group — Application Server
# ─────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "vaultbridge-ec2-sg"
  description = "Security group for VaultBridge EC2 application server"
  vpc_id      = aws_vpc.main.id

  # SSH access — restricted to engineer IP only
  # Never open to 0.0.0.0/0 — lesson from November 2023 incident.. As e dey Hot..LOL
  ingress {
    description = "SSH from engineer IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # HTTP access — open to internet for application traffic
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access — open to internet for secure application traffic
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic permitted
  # Security groups are stateful — responses to inbound
  # requests are automatically allowed
  egress {
    description = "All outbound traffic permitted"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vaultbridge-ec2-sg"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────
# RDS Security Group — Database Server
# ─────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "vaultbridge-rds-sg"
  description = "Security group for VaultBridge RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL access — from EC2 security group ONLY
  # Referencing SG ID, not CIDR — principle of least privilege
  # Only the application server can reach the database
  # This is architecturally enforced, not just policy
  ingress {
    description     = "PostgreSQL from EC2 security group only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # All outbound traffic permitted
  egress {
    description = "All outbound traffic permitted"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vaultbridge-rds-sg"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}
