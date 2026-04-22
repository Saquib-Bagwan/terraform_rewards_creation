output "api_endpoints" {
  description = "Map of api key -> invoke URL for REST APIs"
  value = { for k, v in aws_api_gateway_rest_api.this : k => "https://${v.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${try(aws_api_gateway_stage.this[k].stage_name, "")}" }
}

