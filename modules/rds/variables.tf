variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Database instance class (e.g., db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "engine" {
  description = "Database engine (mysql or postgres)"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default = ""
}

variable "db_identifier" {
  description = "Database instance identifier"
  type        = string
  default     = ""
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, standard)"
  type        = string
  default     = "gp2"
}

variable "security_group_ids" {
  description = "List of security group IDs for the RDS instance"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip creating a final snapshot when deleting"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Whether to deploy in multiple availability zones"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 0
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS"
  type        = list(string)
}
