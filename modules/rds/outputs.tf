output "db_endpoint" {
  description = "The endpoint of the RDS database."
  value = aws_db_instance.postgres_db.endpoint
}

output "rds_security_group_id" {
  description = "The security group ID attached to the RDS database."
  value = aws_security_group.rds_sg.id
}