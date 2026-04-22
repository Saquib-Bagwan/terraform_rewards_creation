# =============================================================================
# Root Module — Composes all child modules for Rewards System
# =============================================================================

# =============================================================================
# VPC Module (no dependencies)
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# =============================================================================
# Security Groups Module (depends on: vpc)
# =============================================================================

# Temporarily commented out security modules for testing (WAF/KMS/NAT/Internet-related parts)
# Security Group for EBS (Web Traffic)
# module "sg_ebs" {
#   source = "./modules/security-group"
#
#   sg_name     = "${var.app_name}-ebs-sg"
#   description = "Security group for Elastic Beanstalk environment"
#   vpc_id      = module.vpc.vpc_id
#   allow_http  = true
#   allow_https = true
#   allow_ssh   = true
#   ssh_ingress_cidr = var.ssh_ingress_cidr
# }
#
# Security Group for RDS (Database Access)
# module "sg_rds" {
#   source = "./modules/security-group"
#
#   sg_name                  = "${var.app_name}-rds-sg"
#   description              = "Security group for RDS database"
#   vpc_id                   = module.vpc.vpc_id
#   allow_db_port            = true
#   db_engine                = var.db_engine
#   source_security_group_id = module.sg_ebs.id
# }

# =============================================================================
# IAM Module (depends on: S3 bucket ARN pattern, CloudWatch log group ARNs)
# =============================================================================

module "iam_ebs_service" {
  source = "./modules/iam"

  role_name = "${var.app_name}-ebs-service-role"
  service   = "elasticbeanstalk.amazonaws.com"
}

# =============================================================================
# S3 Bucket Module (no dependencies)
# =============================================================================

module "s3" {
  source = "./modules/s3_bucket"
}

# =============================================================================
# Cognito Module (no dependencies)
# =============================================================================

module "cognito" {
  source = "./modules/cognito"

  user_pool_name = var.user_pool_name
  client_name    = var.client_name
  domain_prefix  = var.domain_prefix
}

# =============================================================================
# Lambda Module (depends on: cognito, iam)
# =============================================================================

module "lambda" {
  source = "./modules/lambda"

  lambdas       = var.lambdas
  user_pool_id  = module.cognito.user_pool_id
  user_pool_arn = module.cognito.user_pool_arn
}

# =============================================================================
# API Gateway Module (depends on: cognito, lambda)
# =============================================================================

module "api_gateway" {
  source = "./modules/api-gateway"

  api_gateways = {
    customer = {
      api_name      = "zapp-customer-api"
      endpoint_type = "REGIONAL"
      stage_name    = "dev"

    routes = [
      {
        route_key        = "POST /customer"
        integration_type = "LAMBDA"
        lambda_arn       = try(module.lambda.lambda_arns["create_user"], "")
      }
    ]

      tags = {
        Environment = "dev"
      }
    }
  }
}

# =============================================================================
# Elastic Beanstalk Module (depends on: vpc, security-groups, iam, s3)
# =============================================================================

module "ebs" {
  source = "./modules/ebs"

  app_name = var.app_name

  # REQUIRED VARIABLES (add these)
  ebs_kms_key_arn       = var.ebs_kms_key_arn
  instance_profile_name = var.instance_profile_name
  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  app_subnet_ids        = var.app_subnet_ids

  security_group_id = var.security_group_id

  instance_type = var.instance_type
  min_instances = var.min_instances
  max_instances = var.max_instances

  scale_up_threshold   = var.scale_up_threshold
  scale_down_threshold = var.scale_down_threshold

  health_check_url = var.health_check_url

  solution_stack_name = var.solution_stack_name

  tags               = var.tags
  ebs_environments   = var.ebs_environments
  log_retention_days = var.log_retention_days
}

# =============================================================================
# RDS Module (depends on: vpc, security-groups)
# =============================================================================

module "rds" {
  source = "./modules/rds"

  db_name            = replace(var.app_name, "-", "")
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
  username           = var.db_username
  password           = var.db_password
  engine             = var.db_engine
  engine_version     = ""
  backup_window      = var.backup_window
  maintenance_window = var.maintenance_window
  # security groups commented out for testing
  security_group_ids  = []
  publicly_accessible = false
  subnet_ids          = module.vpc.private_subnet_ids
  storage_type        = var.storage_type
}

# =============================================================================
# SES Module (no dependencies)
# =============================================================================

## SES module temporarily removed for testing (enable when `ses_email`/`ses_domain` variables are present)
## module "ses" {
##   source = "./modules/ses"
##
##   email  = var.ses_email
##   domain = var.ses_domain
## }

# =============================================================================
# Optional Modules (Commented Out)
# =============================================================================

# ALB Module temporarily disabled for testing
# module "alb" {
#   source = "./modules/alb"
#
#   alb_name               = "${var.app_name}-alb"
#   subnet_ids             = module.vpc.public_subnet_ids
#   # security groups commented out for testing
#   security_group_ids     = []
#   target_group_name      = "${var.app_name}-tg"
#   target_group_port      = 80
#   target_group_protocol  = "HTTP"
#   vpc_id                 = module.vpc.vpc_id
#   health_check_path      = var.health_check_url
#   listener_port          = 80
#   listener_protocol      = "HTTP"
#   # `tags` removed: not expected by this module (was causing validate error)
# }

# Temporarily commented out EIP/ACM/Route53 modules for testing (NAT/Internet/WAF/KMS changes)
# EIP Module - Uncomment if needed for static IPs
# module "eip" {
#   source = "./modules/eip"
#
#   create_eip                 = true
#   eip_count                  = 2
#   eip_name                   = "${var.app_name}-eip"
#   associate_with_nat_gateway = true
#   nat_gateway_count          = 2
#   tags                       = var.tags
# }
#
# ACM Module - Uncomment if needed for SSL certificates
# module "acm" {
#   source = "./modules/acm"
#
#   domain_name                   = "example.com"
#   validation_method             = "DNS"
#   subject_alternative_names     = ["www.example.com"]
#   route53_zone_id               = try(module.route53.zone_id, "")
#   tags                          = var.tags
# }
#
# Route 53 Module - Uncomment if needed for DNS management
# module "route53" {
#   source = "./modules/route53"
#
#   zone_name      = "example.com"
#   a_records = {
#     alb = {
#       name    = "alb"
#       ttl     = 300
#       records = [try(module.alb.alb_dns_name, "")]
#     }
#   }
#   cname_records = {
#     www = {
#       name    = "www"
#       ttl     = 300
#       records = ["example.com"]
#     }
#   }
#   tags = var.tags
# }

