# Cognito Variables
variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "zaps-user-pool"
}

variable "client_name" {
  description = "Name of the Cognito Client"
  type        = string
  default     = "zaps-client"
}

variable "domain_prefix" {
  description = "Domain prefix for Cognito"
  type        = string
  default     = "zaps"
}

# Database Variables
variable "db_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS database"
  type        = string
  sensitive   = true
  default     = "Password123!"
}

variable "db_engine" {
  description = "Database engine type (mysql or postgres)"
  type        = string
  default     = "postgres"
}

# SES Variables
variable "ses_email" {
  description = "Email address to verify in SES"
  type        = string
  default     = "your-email@example.com"
}

variable "ses_domain" {
  description = "Domain to verify in SES (optional)"
  type        = string
  default     = ""
}

variable "api_gateways" {
  type = map(object({
    api_name = string
    routes = list(object({
      route_key        = string
      integration_type = string
      lambda_arn       = optional(string)
      http_url         = optional(string)
    }))
  }))
}

variable "lambdas" {
  type = map(object({
    handler = string
    runtime = string
    filename = string
  }))
}

