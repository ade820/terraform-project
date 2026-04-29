# ─────────────────────────────────────────────
# Data Source: Latest Amazon Linux 2023 AMI
# ─────────────────────────────────────────────
# A data source reads existing information from AWS
# It does NOT create anything — it just looks up values
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────
# Key Pair: SSH access to EC2
# ─────────────────────────────────────────────
# References your LOCAL public key file
# Terraform uploads the PUBLIC key to AWS
# You keep the PRIVATE key locally to SSH in
resource "aws_key_pair" "main" {
  key_name   = "vaultbridge-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name        = "vaultbridge-key"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────
# EC2 Instance: Application Server
# ─────────────────────────────────────────────
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.main.key_name

  # User data runs on first boot ONLY
  # Installs system updates and PostgreSQL client
  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # Log all output for debugging
    exec > /var/log/user-data.log 2>&1

    echo "=== VaultBridge EC2 Bootstrap Starting ==="
    echo "Timestamp: $(date)"

    # Update all system packages
    echo "--- Running system update ---"
    yum update -y

    # Install PostgreSQL 15 client
    # This allows the EC2 to connect to RDS
    echo "--- Installing PostgreSQL 15 ---"
    yum install -y postgresql15

    echo "=== Bootstrap Complete ==="
    echo "Timestamp: $(date)"
  USERDATA

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name        = "vaultbridge-ec2-root-volume"
      Environment = "dev"
      Project     = "Infrastructure-Modernization"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "vaultbridge-app-server"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# ─────────────────────────────────────────────
# Elastic IP: Static public IP for EC2
# ─────────────────────────────────────────────
# Without Elastic IP, the public IP changes every
# time the instance is stopped and started.
# Elastic IP is static — it stays the same always.
resource "aws_eip" "main" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  # Elastic IP depends on Internet Gateway existing first
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "vaultbridge-eip"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}
