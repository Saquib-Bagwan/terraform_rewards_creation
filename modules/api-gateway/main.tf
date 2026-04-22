#############################################
# DATA SOURCES
#############################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################################
# LOCALS (IMPORTANT)
#############################################

locals {
  route_map = {
    for pair in flatten([
      for api_key, api in var.api_gateways : [
        for idx, route in api.routes : {
          key     = "${api_key}_${idx}"
          api_key = api_key
          route   = route
        }
      ]
    ]) : pair.key => pair
  }
}

#############################################
# REST API
#############################################

resource "aws_api_gateway_rest_api" "this" {
  for_each = var.api_gateways

  name        = each.value.api_name
  description = try(each.value.description, "")

  endpoint_configuration {
    types = [try(each.value.endpoint_type, "REGIONAL")]
  }

  tags = try(each.value.tags, {})
}

#############################################
# RESOURCE (PATH)
#############################################

resource "aws_api_gateway_resource" "this" {
  for_each = local.route_map

  rest_api_id = aws_api_gateway_rest_api.this[each.value.api_key].id
  parent_id   = aws_api_gateway_rest_api.this[each.value.api_key].root_resource_id

  path_part = replace(split(" ", each.value.route.route_key)[1], "/", "")
}

#############################################
# METHOD
#############################################

resource "aws_api_gateway_method" "this" {
  for_each = local.route_map

  rest_api_id = aws_api_gateway_rest_api.this[each.value.api_key].id
  resource_id = aws_api_gateway_resource.this[each.key].id

  http_method   = split(" ", each.value.route.route_key)[0]
  authorization = "NONE"
}

#############################################
# INTEGRATION (LAMBDA / HTTP)
#############################################

resource "aws_api_gateway_integration" "this" {
  for_each = local.route_map

  rest_api_id = aws_api_gateway_rest_api.this[each.value.api_key].id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = aws_api_gateway_method.this[each.key].http_method

  type = each.value.route.integration_type == "LAMBDA" ? "AWS_PROXY" : "HTTP_PROXY"

  integration_http_method = each.value.route.integration_type == "LAMBDA" ? "POST" : "ANY"

  uri = each.value.route.integration_type == "LAMBDA" ? each.value.route.lambda_arn : each.value.route.http_url
}

#############################################
# DEPLOYMENT
#############################################

resource "aws_api_gateway_deployment" "this" {
  for_each = aws_api_gateway_rest_api.this

  rest_api_id = each.value.id

  triggers = {
    redeploy = timestamp()
  }

  depends_on = [
    aws_api_gateway_integration.this
  ]
}

#############################################
# STAGE
#############################################

resource "aws_api_gateway_stage" "this" {
  for_each = aws_api_gateway_deployment.this

  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  deployment_id = each.value.id
  stage_name    = try(var.api_gateways[each.key].stage_name, "dev")
}

#############################################
# LAMBDA PERMISSION
#############################################

resource "aws_lambda_permission" "this" {
  for_each = {
    for k, v in local.route_map :
    k => v if v.route.integration_type == "LAMBDA"
  }

  statement_id  = "AllowInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.route.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this[each.value.api_key].id}/*/*/*"
}

#############################################
# VARIABLES
#############################################

variable "api_gateways" {
  type = map(object({
    api_name      = string
    description   = optional(string)
    endpoint_type = optional(string)
    stage_name    = optional(string)

    routes = list(object({
      route_key        = string
      integration_type = string
      lambda_arn       = optional(string)
      http_url         = optional(string)
    }))

    tags = optional(map(string))
  }))
}