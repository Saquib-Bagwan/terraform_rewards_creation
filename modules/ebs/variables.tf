variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "env_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
}

variable "solution_stack_name" {
  description = "The solution stack name to use for the environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the environment"
  type        = string
  default     = "t2.micro"
}

variable "app_version" {
  description = "Version label for the application"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket containing the application version"
  type        = string
}

variable "s3_key" {
  description = "S3 key (path) to the application version in the bucket"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to associate with the EBS environment"
  type        = string
  default     = ""
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for the EBS environment"
  type        = list(string)
  default     = []
}

variable "app_path" {
  description = "Local path of JAR file"
  type        = string
}
