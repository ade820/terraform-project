# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vaultbridge-vpc"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# Public Subnet - AZ 1 (for EC2 application server)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "vaultbridge-public-subnet-1"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
    Tier        = "Public"
  }
}

# Public Subnet - AZ 2 (for high availability)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "vaultbridge-public-subnet-2"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
    Tier        = "Public"
  }
}

# Private Subnet - AZ 1 (for RDS database)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "vaultbridge-private-subnet-1"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
    Tier        = "Private"
  }
}

# Private Subnet - AZ 2 (required for RDS subnet group)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "vaultbridge-private-subnet-2"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
    Tier        = "Private"
  }
}

# Internet Gateway - allows public subnets to reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "vaultbridge-igw"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# Public Route Table - routes internet traffic through the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "vaultbridge-public-rt"
    Environment = "dev"
    Project     = "Infrastructure-Modernization"
    ManagedBy   = "Terraform"
  }
}

# Associate Public Route Table with Public Subnet 1
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associate Public Route Table with Public Subnet 2
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
