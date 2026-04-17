output "api_endpoints" {
  value = { for k, v in aws_apigatewayv2_api.this : k => v.api_endpoint }
}
