variable "lambdas" {
  type = map(object({
    handler = string
    runtime = string
    filename = string
  }))
}

variable "user_pool_id" {
  type = string
}

variable "user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}