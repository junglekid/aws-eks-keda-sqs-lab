### SQS App
# Create SSL Certificate using AWS ACM for SQS App
resource "aws_acm_certificate" "sqs_app" {
  domain_name       = "sqs-app.${local.public_base_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Validate SSL Certificate using DNS for SQS App
resource "aws_route53_record" "sqs_app_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sqs_app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

# Retrieve SSL Certificate ARN from AWS ACM for SQS App
resource "aws_acm_certificate_validation" "sqs_app" {
  certificate_arn         = aws_acm_certificate.sqs_app.arn
  validation_record_fqdns = [for record in aws_route53_record.sqs_app_validation : record.fqdn]
}

### Headlamp
# Create SSL Certificate using AWS ACM for Headlamp
resource "aws_acm_certificate" "headlamp" {
  domain_name       = "headlamp.${local.public_base_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Validate SSL Certificate using DNS for SQS App
resource "aws_route53_record" "headlamp_validation" {
  for_each = {
    for dvo in aws_acm_certificate.headlamp.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

# Retrieve SSL Certificate ARN from AWS ACM for SQS App
resource "aws_acm_certificate_validation" "headlamp" {
  certificate_arn         = aws_acm_certificate.headlamp.arn
  validation_record_fqdns = [for record in aws_route53_record.headlamp_validation : record.fqdn]
}
