resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.description
  vpc_id      = var.vpc_id != "" ? var.vpc_id : null

  # HTTP ingress
  dynamic "ingress" {
    for_each = var.allow_http ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from internet"
    }
  }

  # HTTPS ingress
  dynamic "ingress" {
    for_each = var.allow_https ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from internet"
    }
  }

  # SSH ingress
  dynamic "ingress" {
    for_each = var.allow_ssh ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow SSH from internet (restrict in production)"
    }
  }

  # Database port ingress (MySQL: 3306, PostgreSQL: 5432)
  dynamic "ingress" {
  for_each = var.allow_db_port && var.source_security_group_id != "" ? [1] : []
  content {
    from_port       = var.db_engine == "postgres" ? 5432 : 3306
    to_port         = var.db_engine == "postgres" ? 5432 : 3306
    protocol        = "tcp"
    security_groups = [var.source_security_group_id] 
    description     = "Allow DB access from app SG"
  }
}

  # Custom ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", "Custom rule")
    }
  }

  # Default egress - allow all outbound traffic
  dynamic "egress" {
    for_each = length(var.egress_rules) > 0 ? [] : [1]
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  }

  # Custom egress rules
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = lookup(egress.value, "description", "Custom rule")
    }
  }

  tags = {
    Name = var.sg_name
  }
}