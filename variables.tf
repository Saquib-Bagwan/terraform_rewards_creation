# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "app_name" {
  description = "Name of the application used for resource naming"
  type        = string
  default     = "banking-credit-card-app"
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk solution stack name"
  type        = string
  default     = "64bit Amazon Linux 2023 v4.4.4 running Corretto 17"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones (minimum 3)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "alb_ingress_cidr" {
  description = "CIDR block allowed to reach the ALB (0.0.0.0/0 for public access)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_ingress_cidr" {
  description = "CIDR block allowed to reach SSH (set to admin IP CIDR to restrict)"
  type        = string
  default     = ""
}

variable "ebs_environments" {
  description = "Map of Elastic Beanstalk environments to create from the root module. Key is suffix appended to app_name. Values must include instance_type, min_instances, max_instances, health_check_url, solution_stack_name."
  type = map(object({
    instance_type       = string
    min_instances       = number
    max_instances       = number
    health_check_url    = string
    solution_stack_name = string
  }))
  default = {}
}

variable "vpc_id" {
  description = "VPC ID for Elastic Beanstalk deployment"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for Elastic Beanstalk load balancer"
  type        = list(string)
  default     = []
}

variable "app_subnet_ids" {
  description = "Private subnet IDs for Elastic Beanstalk application instances"
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Security Group ID for Elastic Beanstalk"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Compute — Elastic Beanstalk
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for Elastic Beanstalk environment"
  type        = string
  default     = "c5.xlarge"
}

variable "min_instances" {
  description = "Minimum number of instances in the auto-scaling group"
  type        = number
  default     = 4
}

variable "max_instances" {
  description = "Maximum number of instances in the auto-scaling group"
  type        = number
  default     = 12
}

variable "scale_up_threshold" {
  description = "CPU utilization percentage to trigger scale-out"
  type        = number
  default     = 60
}

variable "scale_down_threshold" {
  description = "CPU utilization percentage to trigger scale-in"
  type        = number
  default     = 30
}

variable "health_check_url" {
  description = "Health check URL path for the Elastic Beanstalk environment"
  type        = string
  default     = "/actuator/health"
}

# -----------------------------------------------------------------------------
# Database — RDS MySQL
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class for the primary database"
  type        = string
  default     = "db.r6g.2xlarge"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB for the RDS instance"
  type        = number
  default     = 500
}

variable "db_max_storage" {
  description = "Maximum storage in GB for RDS storage autoscaling"
  type        = number
  default     = 2000
}

variable "db_iops" {
  description = "Provisioned IOPS for the RDS instance (gp3)"
  type        = number
  default     = 3000
}

variable "db_throughput" {
  description = "Storage throughput in MB/s for the RDS instance (gp3)"
  type        = number
  default     = 125
}

variable "backup_window" {
  description = "Preferred backup window in UTC (format HH:MM-HH:MM)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window in UTC (format ddd:HH:MM-ddd:HH:MM)"
  type        = string
  default     = "Sun:04:00-Sun:05:00"
}

variable "create_read_replica" {
  description = "Whether to create a read replica for the RDS instance"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Master password for the RDS instance. Pass via TF_VAR_db_password environment variable or secrets manager."
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Database engine (mysql or postgres)"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "zapsadmin"
}

variable "storage_type" {
  description = "RDS storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for ALB HTTPS termination"
  type        = string
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute window before WAF rate-limiting blocks the IP"
  type        = number
  default     = 2000
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "sns_endpoint" {
  description = "Email or endpoint for SNS alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Disaster Recovery
# -----------------------------------------------------------------------------

variable "dr_region" {
  description = "AWS region for cross-region disaster recovery snapshot copies"
  type        = string
  default     = "us-west-2"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Common resource tags applied to all infrastructure components"
  type        = map(string)
  default = {
    Environment = "production"
    Application = "banking-credit-card"
    Owner       = "platform-engineering"
    CostCenter  = "CC-12345"
    ManagedBy   = "terraform"
    Compliance  = "pci-dss"
  }
}


# -----------------------------------------------------------------------------
# Subnets (REQUIRED for VPC module)
# -----------------------------------------------------------------------------

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  default = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

# -----------------------------------------------------------------------------
# EBS Required Inputs
# -----------------------------------------------------------------------------

variable "ebs_kms_key_arn" {
  description = "KMS Key ARN for EBS volume encryption"
  type        = string
  default     = ""
}

variable "instance_profile_name" {
  description = "IAM Instance Profile for EC2 instances in EBS"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Cognito Configuration
# -----------------------------------------------------------------------------

variable "user_pool_name" {
  description = "Name for Cognito User Pool"
  type        = string
  default     = "rewards-user-pool"
}

variable "client_name" {
  description = "Name for Cognito Application Client"
  type        = string
  default     = "rewards-web-client"
}

variable "domain_prefix" {
  description = "Domain prefix for Cognito Hosted UI"
  type        = string
  default     = "rewards-auth"
}

# -----------------------------------------------------------------------------
# Lambda Configuration
# -----------------------------------------------------------------------------

variable "lambdas" {
  description = "Map of Lambda functions configuration"
  type = map(object({
    handler  = string
    runtime  = string
    filename = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# API Gateway Configuration
# -----------------------------------------------------------------------------

variable "api_gateways" {
  description = "Map of API gateways and their routes"
  type = map(object({
    api_name = string
    routes = list(object({
      route_key        = string
      integration_type = string
      lambda_arn       = optional(string)
      http_url         = optional(string)
    }))
  }))
  default = {}
}
