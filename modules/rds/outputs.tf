output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.this.port
}

output "db_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.this.id
}