user_pool_name = "zaps-user-pool"
client_name    = "zaps-client"
domain_prefix  = "zaps-auth-1234"

api_gateways = {
  api1 = {
    api_name = "user-api"
    routes = [
      {
        route_key        = "GET /users"
        integration_type = "LAMBDA"
        lambda_arn       = "arn:aws:lambda:xxx:user"
      }
    ]
  }

  api2 = {
    api_name = "external-api"
    routes = [
      {
        route_key        = "GET /posts"
        integration_type = "HTTP"
        http_url         = "https://jsonplaceholder.typicode.com/posts"
      }
    ]
  }
}

lambdas = {
  create_user = {
    handler = "lambda_function.lambda_handler"
    runtime = "python3.8"
    filename = "modules/lambda/zip/zapp_admin_lambda_createuser_me-south-1-qa.zip"
  }

  login_user = {
    handler = "lambda_function.lambda_handler"
    runtime = "python3.8"
    filename = "modules/lambda/zip/send_email_redemption_lambda.zip"
  }
}
