# =============================================================================
# General Configuration
# =============================================================================

aws_region = "ap-southeast-1"
app_name   = "zaps-rewards"

tags = {
  Environment = "production"
  Application = "rewards"
  Team        = "backend"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}

# =============================================================================
# Network Configuration
# =============================================================================

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
alb_ingress_cidr   = "0.0.0.0/0"

# =============================================================================
# Compute — Elastic Beanstalk Configuration
# =============================================================================

instance_type        = "c5.xlarge"
min_instances        = 4
max_instances        = 12
scale_up_threshold   = 60
scale_down_threshold = 30
health_check_url     = "/actuator/health"
solution_stack_name  = "64bit Amazon Linux 2023 v4.4.4 running Corretto 25"
ebs_app_version      = "v1.0.0"
ebs_app_source       = "app/app.jar"

# =============================================================================
# Database — RDS Configuration
# =============================================================================

db_instance_class = "db.m7g.large"
# RDS
db_allocated_storage = 500
db_max_storage       = 500
storage_type         = "gp3"
db_engine            = "postgres"
db_username          = "zapsadmin"
# NOTE: db_password is NOT stored here. Pass via TF_VAR_db_password
#       environment variable or AWS Secrets Manager.
db_password = "ChangeMe123!"

backup_window       = "03:00-04:00"
maintenance_window  = "Sun:04:00-Sun:05:00"
create_read_replica = false

# =============================================================================
# Security Configuration
# =============================================================================

acm_certificate_arn = ""
waf_rate_limit      = 2000
ssh_ingress_cidr    = "" # set to your admin IP CIDR (e.g. 1.2.3.4/32) to restrict SSH

# =============================================================================
# Cognito Configuration
# =============================================================================

user_pool_name = "zaps-user-pool"
client_name    = "zaps-client"
domain_prefix  = "zaps-auth"

# =============================================================================
# API Gateway Configuration
# =============================================================================

api_gateways = {
  api1 = {
    api_name        = "user-api"
    protocol        = "HTTP"
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
    stage_name      = "prod"
    tags            = {}
    routes = [
      {
        route_key        = "GET /users"
        integration_type = "LAMBDA"
        lambda_arn       = "arn:aws:lambda:ap-southeast-1:ACCOUNT_ID:function:user-handler"
      }
    ]
  }

  api2 = {
    api_name        = "external-api"
    protocol        = "HTTP"
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
    stage_name      = "prod"
    tags            = {}
    routes = [
      {
        route_key        = "GET /posts"
        integration_type = "HTTP"
        http_url         = "https://jsonplaceholder.typicode.com/posts"
      }
    ]
  }
}

# =============================================================================
# Lambda Configuration
# =============================================================================

lambdas = {
  create_user = {
    handler  = "lambda_function.lambda_handler"
    runtime  = "python3.8"
    filename = "modules/lambda/zip/zapp_admin_lambda_createuser_me-south-1-qa.zip"
  }

  login_user = {
    handler  = "lambda_function.lambda_handler"
    runtime  = "python3.8"
    filename = "modules/lambda/zip/send_email_redemption_lambda.zip"
  }
}

# =============================================================================
# SES Configuration
# =============================================================================

ses_email  = ""
ses_domain = ""

# =============================================================================
# Monitoring Configuration
# =============================================================================

sns_endpoint      = ""
enable_monitoring = true

# =============================================================================
# Elastic Beanstalk — Multiple Environments
# =============================================================================
ebs_environments = {
  customer = {
    instance_type       = "c5.xlarge"
    min_instances       = 4
    max_instances       = 12
    health_check_url    = "/actuator/health"
    solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Corretto 25"
  }
  # admin = {
  #   instance_type       = "t4g.medium"
  #   min_instances       = 1
  #   max_instances       = 2
  #   health_check_url    = "/actuator/health"
  #   solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Corretto 25"
  # }

  # merchant = {
  #   instance_type       = "t4g.medium"
  #   min_instances       = 1
  #   max_instances       = 2
  #   health_check_url    = "/actuator/health"
  #   solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Corretto 25"
  # }

  # client = {
  #   instance_type       = "t4g.medium"
  #   min_instances       = 1
  #   max_instances       = 2
  #   health_check_url    = "/actuator/health"
  #   solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Corretto 25"
  # }
}

