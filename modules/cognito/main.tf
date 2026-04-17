# Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = "zaps-user-pool"

  # Login options (username + email)
  alias_attributes = ["email"]

  # Only email verification
  auto_verified_attributes = ["email"]

  # Email attribute
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  # Phone number (optional - NOT required)
  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = false   
    mutable             = true
  }

  # Custom Attributes for User Type
  schema {
    name                = "user_type"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Custom Attributes for Store Name
  schema {
    name                = "storeName"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Custom Attributes for Store ID
  schema {
    name                = "storeId"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Custom Attributes for User Type ID
  schema {
    name                = "userTypeId"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Custom Attributes for User ID
  schema {
    name                = "userId"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Custom Attributes for Correlation ID
  schema {
    name                = "correlationId"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
  }

  # Account recovery (Best Practice)
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Project = "zaps"
  }

  lifecycle {
    ignore_changes = [schema]
  }
}

# User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "zaps-client"
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = false
}

# Cognito Domain (Hosted UI)
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "zaps-auth-domain-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.this.id
}

# Random suffix (to avoid domain conflict)
resource "random_id" "suffix" {
  byte_length = 4
}
