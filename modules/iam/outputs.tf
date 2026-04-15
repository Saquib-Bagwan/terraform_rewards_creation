output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "ebs_service_role" {
  value = aws_iam_role.ebs_service_role.name
}

output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2_profile.name
}