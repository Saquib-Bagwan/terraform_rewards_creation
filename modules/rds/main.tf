resource "aws_db_subnet_group" "this" {
  name       = "zaps-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "this" {
  identifier = var.db_identifier != "" ? var.db_identifier : "zaps-db"

  # Storage
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  # Engine
  engine         = var.engine
  instance_class = var.instance_class

  # Database Config
  db_name  = var.db_name
  username = var.username
  password = var.password

  # Networking (FIXED)
  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.this.name   

  # Safety
  skip_final_snapshot = true
  deletion_protection = false

  # Availability
  multi_az = false

  # Backup
  backup_retention_period = 7

  # Tags
  tags = {
    Name        = "zaps-db"
    Environment = "qa"
  }
}
