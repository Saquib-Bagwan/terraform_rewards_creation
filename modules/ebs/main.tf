########################################
# S3 Object (UPLOAD JAR)
########################################
resource "aws_s3_object" "app" {
  bucket = var.s3_bucket
  key    = var.s3_key

  # ✅ SAFE PATH
  source = "${path.root}/${var.app_path}"
  etag   = filemd5("${path.root}/${var.app_path}")
}

########################################
# Elastic Beanstalk Application
########################################
resource "aws_elastic_beanstalk_application" "this" {
  name = var.app_name
}

########################################
# Application Version
########################################
resource "aws_elastic_beanstalk_application_version" "this" {
  name        = var.app_version
  application = aws_elastic_beanstalk_application.this.name

  bucket = var.s3_bucket
  key    = var.s3_key

  depends_on = [aws_s3_object.app]   # ✅ IMPORTANT
}

########################################
# IAM Role (Beanstalk Service Role)
########################################
resource "aws_iam_role" "ebs_service_role" {
  name = "${var.app_name}-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_service_policy" {
  role       = aws_iam_role.ebs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

########################################
# IAM Role (EC2 Instances)
########################################
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker_tier" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "multicontainer" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

########################################
# Instance Profile (MANDATORY)
########################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# Elastic Beanstalk Environment
########################################
resource "aws_elastic_beanstalk_environment" "this" {
  name        = var.env_name
  application = aws_elastic_beanstalk_application.this.name

  # ✅ UPDATED (no solution_stack_name)
  platform_arn = "arn:aws:elasticbeanstalk:ap-southeast-1::platform/Corretto 17 running on 64bit Amazon Linux 2/3.5.6"

  version_label = aws_elastic_beanstalk_application_version.this.name

  ########################################
  # Instance Config
  ########################################
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  ########################################
  # Security Group
  ########################################
  setting {
    namespace = "aws:ec2:vpc"
    name      = "SecurityGroups"
    value     = var.security_group_id
  }

  ########################################
  # Environment Type
  ########################################
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  ########################################
  # Health Check
  ########################################
  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/"
  }

  ########################################
  # Subnets (Optional)
  ########################################
  dynamic "setting" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = join(",", var.vpc_subnet_ids)
    }
  }

  dynamic "setting" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = join(",", var.vpc_subnet_ids)
    }
  }

  ########################################
  # IAM Roles (CRITICAL)
  ########################################
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.ebs_service_role.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_profile.name
  }

  ########################################
  # Dependencies (VERY IMPORTANT)
  ########################################
  depends_on = [
    aws_iam_role_policy_attachment.ebs_service_policy,
    aws_iam_instance_profile.ec2_profile,
    aws_elastic_beanstalk_application_version.this
  ]
}