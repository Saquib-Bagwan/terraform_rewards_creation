# -----------------------------------------------------------------------------
# Elastic Beanstalk Module — Variables
# Requirements: 9.4
# -----------------------------------------------------------------------------

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk solution stack name (e.g. Corretto 17 running on 64bit Amazon Linux 2023)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EB environment will be deployed"
  type        = string
}

variable "app_subnet_ids" {
  description = "List of private application subnet IDs for EB instances"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EB-managed load balancer"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for EB environment instances"
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
  description = "Average CPU utilization percentage to trigger scale-out"
  type        = number
  default     = 60
}

variable "scale_down_threshold" {
  description = "Average CPU utilization percentage to trigger scale-in"
  type        = number
  default     = 30
}

variable "health_check_url" {
  description = "Health check URL path for enhanced health reporting"
  type        = string
  default     = "/actuator/health"
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for EB EC2 instances"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to EB instances"
  type        = string
  default     = ""
}

variable "ebs_kms_key_arn" {
  description = "ARN of the KMS key used for EBS volume encryption"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common resource tags applied to all Elastic Beanstalk resources"
  type        = map(string)
  default     = {}
}

variable "ebs_environments" {
  description = "Map of Elastic Beanstalk environments to create. Key is a short suffix used in the environment name. Value must include instance_type, min_instances, max_instances, health_check_url and solution_stack_name. Example: { customer = { instance_type = \"c5.xlarge\", min_instances=4, max_instances=12, health_check_url=\"/actuator/health\", solution_stack_name=\"...\" } }"
  type = map(object({
    instance_type        = string
    min_instances        = number
    max_instances        = number
    health_check_url     = string
    solution_stack_name  = string
  }))
  default = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days for EB logs"
  type        = number
  default     = 90
}
