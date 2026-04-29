output "ec2_public_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.main.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (hostname:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "Public subnet 1 ID"
  value       = aws_subnet.public_1.id
}

output "private_subnet_1_id" {
  description = "Private subnet 1 ID"
  value       = aws_subnet.private_1.id
}
