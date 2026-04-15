########################################
# IAM Assume Role
########################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

########################################
# Lambda IAM Role
########################################
resource "aws_iam_role" "lambda_role" {
  for_each = var.lambdas

  name               = "${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

########################################
# Attach Basic Execution Role (CloudWatch Logs)
########################################
resource "aws_iam_role_policy_attachment" "basic_execution" {
  for_each = var.lambdas

  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########################################
# Cognito Access Policy (Scoped)
########################################
resource "aws_iam_role_policy" "cognito_access" {
  for_each = var.lambdas

  name = "${each.key}-cognito-policy"
  role = aws_iam_role.lambda_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:ListUsers"
        ]
        Resource = var.user_pool_arn   # ✅ FIX (no "*")
      }
    ]
  })
}

########################################
# SES Access Policy (for email sending)
########################################
resource "aws_iam_role_policy" "ses_access" {
  for_each = var.lambdas

  name = "${each.key}-ses-policy"
  role = aws_iam_role.lambda_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_lambda_function" "this" {
  for_each = var.lambdas

  function_name = each.key
  role          = aws_iam_role.lambda_role[each.key].arn
  handler       = each.value.handler
  runtime       = each.value.runtime

  ########################################
  # FILE (Dummy / Real)
  ########################################
  filename         = each.value.filename
  source_code_hash = filebase64sha256(each.value.filename)

  ########################################
  # Environment Variables
  ########################################
  environment {
    variables = {
      ENVIRONMENT  = "qa"
      USER_POOL_ID = var.user_pool_id
    }
  }

  ########################################
  # Timeout (important for API calls)
  ########################################
  timeout = 10

  ########################################
  # Tags
  ########################################
  tags = {
    Project = "zaps-reward"
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution
  ]
}