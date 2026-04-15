output "lambda_arns" {
  value = {
    for k, v in aws_lambda_function.this :
    k => v.arn   # ✅ REAL Lambda ARN
  }
}