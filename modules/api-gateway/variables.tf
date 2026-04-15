variable "api_gateways" {
  description = "Map of API gateways and their routes"
  type = map(object({
    api_name = string
    routes = list(object({
      route_key        = string
      integration_type = string   # LAMBDA | HTTP
      lambda_arn       = optional(string)
      http_url         = optional(string)
    }))
  }))
}