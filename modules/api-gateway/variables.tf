variable "api_gateways" {
  description = "Map of API gateways and their routes. Each value may include optional keys: domain_name and certificate_arn for custom domain mapping."
  type    = map(any)
  default = {}
}
