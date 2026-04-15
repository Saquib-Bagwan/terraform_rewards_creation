resource "aws_ses_email_identity" "this" {
  email = var.email
}

resource "aws_ses_domain_identity" "this" {
  count  = var.domain != "" ? 1 : 0
  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  count  = var.domain != "" ? 1 : 0
  domain = var.domain
}

