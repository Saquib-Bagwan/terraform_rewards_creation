# #############################################
# # VARIABLES
# #############################################

# variable "api_gateways" {
#   type = map(object({
#     api_name      = string
#     description   = optional(string)
#     endpoint_type = optional(string)
#     stage_name    = optional(string)

#     routes = list(object({
#       route_key        = string
#       integration_type = string
#       lambda_arn       = optional(string)
#       http_url         = optional(string)
#     }))

#     tags = optional(map(string))
#   }))
# }