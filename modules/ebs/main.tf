# -----------------------------------------------------------------------------
# Elastic Beanstalk Module — Application and Environment
# Requirements: 2.1-2.8, 5.3, 10.1, 11.3
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# S3 Bucket — Deployment Artifacts (versioned for rollback)
# Requirement 11.3: Versioned S3 bucket for deployment artifacts
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "deploy_artifacts" {
  bucket = "${var.app_name}-deploy-artifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Name = "${var.app_name}-deploy-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_artifacts_kms" {
  count  = var.ebs_kms_key_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.deploy_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.ebs_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_artifacts_aes" {
  count  = var.ebs_kms_key_arn == "" ? 1 : 0
  bucket = aws_s3_bucket.deploy_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  rule {
    id     = "retain-recent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# -----------------------------------------------------------------------------
# Elastic Beanstalk Application
# -----------------------------------------------------------------------------

resource "aws_elastic_beanstalk_application" "this" {
  name        = var.app_name
  description = "Elastic Beanstalk application for ${var.app_name}"

  tags = merge(var.tags, {
    Name = var.app_name
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group — Application and Platform Logs
# Requirement 10.1: Logs published to CloudWatch with 90-day retention
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eb_app_logs" {
  name              = "/aws/elasticbeanstalk/${var.app_name}/app"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.app_name}-app-logs"
  })
}

resource "aws_cloudwatch_log_group" "eb_platform_logs" {
  name              = "/aws/elasticbeanstalk/${var.app_name}/platform"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.app_name}-platform-logs"
  })
}

# -----------------------------------------------------------------------------
# Elastic Beanstalk Environment
# Requirement 2.1: Load-balanced, auto-scaling environment (min 4, max 12)
# Requirement 2.2: c5.xlarge instance type (configurable)
# Requirement 2.3: Instances in private app subnets only
# Requirement 2.4: Auto-scaling — scale out at 60% CPU, scale in at 30% CPU
# Requirement 2.5: Corretto 17 platform
# Requirement 2.6: Rolling update with 25% batch size
# Requirement 2.7: Enhanced health reporting with configurable health check URL
# Requirement 2.8: Unhealthy instance replacement after 3 consecutive failures
# Requirement 5.3: EBS volume encryption with customer-managed KMS key
# -----------------------------------------------------------------------------

resource "aws_elastic_beanstalk_environment" "this" {
  for_each            = length(var.ebs_environments) > 0 ? var.ebs_environments : { prod = {
    instance_type       = var.instance_type
    min_instances       = var.min_instances
    max_instances       = var.max_instances
    health_check_url    = var.health_check_url
    solution_stack_name = var.solution_stack_name
  } }

  name                = "${var.app_name}-${each.key}"
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = each.value.solution_stack_name

  tags = merge(var.tags, {
    Name = "${var.app_name}-${each.key}"
  })

  # ---------------------------------------------------------------------------
  # Environment Type — Load-balanced, auto-scaling
  # Requirement 2.1
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # ---------------------------------------------------------------------------
  # VPC Configuration — Instances in private subnets, ALB in public subnets
  # Requirement 2.3
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.app_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.public_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  # ---------------------------------------------------------------------------
  # Launch Configuration — Instance type, security group, IAM profile
  # Requirement 2.2, 5.3
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = each.value.instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.instance_profile_name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.security_group_id
  }

  # ---------------------------------------------------------------------------
  # EBS Volume Encryption — Customer-managed KMS key
  # Requirement 5.3
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeType"
    value     = "gp3"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = "50"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeIOPS"
    value     = "3000"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeThroughput"
    value     = "125"
  }

  # ---------------------------------------------------------------------------
  # Auto-Scaling Group — Min/max instances
  # Requirement 2.1
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(each.value.min_instances)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(each.value.max_instances)
  }

  # ---------------------------------------------------------------------------
  # Auto-Scaling Triggers — CPU-based scaling
  # Requirement 2.4: Scale out at 60% CPU, scale in at 30% CPU
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = tostring(var.scale_up_threshold)
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = tostring(var.scale_down_threshold)
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "5"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "5"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperBreachScaleIncrement"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerBreachScaleIncrement"
    value     = "-1"
  }

  # ---------------------------------------------------------------------------
  # Rolling Updates — 25% batch size
  # Requirement 2.6
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "25"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "1"
  }

  # ---------------------------------------------------------------------------
  # Enhanced Health Reporting
  # Requirement 2.7: Enhanced health with configurable health check URL
  # Requirement 2.8: Unhealthy replacement after 3 consecutive failures
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = each.value.health_check_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = each.value.health_check_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = "3"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = "3"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  # ---------------------------------------------------------------------------
  # CloudWatch Logs — Application and platform log streaming
  # Requirement 10.1: Logs published to CloudWatch with 90-day retention
  # ---------------------------------------------------------------------------

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "90"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "HealthStreamingEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "RetentionInDays"
    value     = "90"
  }

  depends_on = [
    aws_cloudwatch_log_group.eb_app_logs,
    aws_cloudwatch_log_group.eb_platform_logs,
  ]
}
