output "endpoint_url" {
  description = "Map of environment suffix -> URL of the Elastic Beanstalk environment"
  value       = { for k, env in aws_elastic_beanstalk_environment.this : k => env.endpoint_url }
}

output "environment_id" {
  description = "Map of environment suffix -> ID of the Elastic Beanstalk environment"
  value       = { for k, env in aws_elastic_beanstalk_environment.this : k => env.id }
}

output "application_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.this.name
}

# output "ec2_iam_role_arn" {
#   description = "ARN of the EC2 IAM role"
#   value       = aws_iam_role.ec2_role.arn
# }

# output "service_iam_role_arn" {
#   description = "ARN of the EBS service IAM role"
#   value       = aws_iam_role.ebs_service_role.arn
# }
