VPC Module
module "vpc" {
  source = "./modules/vpc"
}

# Cognito Module (needed for Lambda)
module "cognito" {
  source = "./modules/cognito"

  user_pool_name = var.user_pool_name
  client_name    = var.client_name
  domain_prefix  = var.domain_prefix
}

# API Gateway Module
# module "api_gateway" {
#   source = "./modules/api-gateway"
#   api_gateways = var.api_gateways
# }

# Lambda Module (only this will be applied)
module "lambda" {
  source = "./modules/lambda"

  lambdas = var.lambdas

  user_pool_id  = module.cognito.user_pool_id
  user_pool_arn = module.cognito.user_pool_arn
}

S3 Bucket Module
module "s3" {
  source = "./modules/s3_bucket"
}

# IAM Module for EBS roles
# module "iam_ebs_service" {
#   source = "./modules/iam"

#   role_name = "ebs-service-role"
#   service   = "elasticbeanstalk.amazonaws.com"
# }

# Security Group for EBS (Web Traffic)
# module "sg_ebs" {
#   source = "./modules/security-group"

#   sg_name     = "ebs-sg"
#   description = "Security group for Elastic Beanstalk environment"
#   vpc_id      = module.vpc.vpc_id
#   allow_http  = true
#   allow_https = true
#   allow_ssh   = true
# }

# Security Group for RDS (Database Access)
# module "sg_rds" {
#   source = "./modules/security-group"

#   sg_name                  = "rds-sg"
#   description              = "Security group for RDS database"
#   vpc_id                   = module.vpc.vpc_id
#   allow_db_port            = true
#   db_engine                = var.db_engine
#   source_security_group_id = module.sg_ebs.id
# }

# Elastic Beanstalk Module
# module "ebs" {
#   source = "./modules/ebs"

#   app_name            = "zaps-app"
#   env_name            = "zaps-env"
#   app_version         = "v1"
#   s3_bucket           = module.s3.bucket_name
#   s3_key              = "app/app.jar"
#   app_path            = "app/app.jar"
#   instance_type       = "t2.micro"
#   security_group_id   = module.sg_ebs.id

#   solution_stack_name = "64bit Amazon Linux 2 v3.5.6 running Corretto 17"
# }

# SES Module
# module "ses" {
#   source = "./modules/ses"

#   email  = var.ses_email
#   domain = var.ses_domain
# }

# RDS Module
# module "rds" {
#   source = "./modules/rds"

#   db_name             = "zapsdb"
#   username            = var.db_username
#   password            = var.db_password
#   instance_class      = "db.t3.micro"
#   engine              = var.db_engine

#   engine_version = ""  

#   security_group_ids  = [module.sg_rds.id]
#   publicly_accessible = false

#   subnet_ids = module.vpc.private_subnet_ids
# }

