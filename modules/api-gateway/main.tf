
resource "aws_apigatewayv2_api" "this" {
  for_each      = var.api_gateways
  name          = each.value.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "this" {

  for_each = {
    for pair in flatten([
      for api_key, api in var.api_gateways : [
        for idx, route in api.routes : {
          key     = "${api_key}_${idx}"
          api_key = api_key
          route   = route
        }
      ]
    ]) : pair.key => merge(pair.route, { api_key = pair.api_key })
  }

  api_id = aws_apigatewayv2_api.this[each.value.api_key].id

  integration_type      = each.value.integration_type == "LAMBDA" ? "AWS_PROXY" : "HTTP_PROXY"
  integration_uri       = each.value.integration_type == "LAMBDA" ? each.value.lambda_arn : each.value.http_url
  payload_format_version = each.value.integration_type == "LAMBDA" ? "2.0" : null
}

resource "aws_apigatewayv2_route" "this" {
  for_each = {
    for k, v in aws_apigatewayv2_integration.this :
    k => v
  }

  api_id    = aws_apigatewayv2_api.this[split("_", each.key)[0]].id
  route_key = var.api_gateways[split("_", each.key)[0]].routes[tonumber(split("_", each.key)[1])].route_key
  target    = "integrations/${each.value.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  for_each    = aws_apigatewayv2_api.this
  api_id      = each.value.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "this" {
  for_each = {
    for k, v in aws_apigatewayv2_integration.this :
    k => v if v.integration_type == "LAMBDA"
  }

  statement_id  = "AllowInvoke-${each.key}-${aws_apigatewayv2_api.this[each.value.api_key].id}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this[each.value.api_key].execution_arn}/*/*"
}
