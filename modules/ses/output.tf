output "email_identity" {
  value = aws_ses_email_identity.this.email
}

output "domain_identity" {
  value = try(aws_ses_domain_identity.this[0].domain, null)
}