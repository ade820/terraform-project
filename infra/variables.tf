variable "aws_region" {
  description = "AWS region where all resources will be provisioned"
  type        = string
  default     = "eu-west-1"
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR notation (e.g. 102.89.23.1/32) for SSH access"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}
