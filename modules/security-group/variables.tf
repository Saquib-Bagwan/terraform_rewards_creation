variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
  default     = ""
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = optional(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = optional(string)
  }))
  default = []
}

variable "allow_http" {
  description = "Allow HTTP (port 80) from internet"
  type        = bool
  default     = false
}

variable "allow_https" {
  description = "Allow HTTPS (port 443) from internet"
  type        = bool
  default     = false
}

variable "allow_ssh" {
  description = "Allow SSH (port 22) from internet"
  type        = bool
  default     = false
}

variable "allow_db_port" {
  description = "Allow database port (3306 for MySQL, 5432 for PostgreSQL) from source security group"
  type        = bool
  default     = false
}

variable "db_engine" {
  description = "Database engine type (mysql or postgres)"
  type        = string
  default     = "mysql"
}

variable "source_security_group_id" {
  description = "Source security group ID for database access"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "ssh_ingress_cidr" {
  description = "SSH admin CIDR to restrict SSH access (e.g. 1.2.3.4/32). If empty, defaults to 0.0.0.0/0"
  type        = string
  default     = ""
}
