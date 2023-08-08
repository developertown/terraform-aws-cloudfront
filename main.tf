locals {
  enabled = var.enabled

  name = "${var.name}-${var.environment}%{if var.suffix != ""}-${var.suffix}%{endif}"

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment,
      "ManagedBy"   = "Terraform"
    }
  )
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  count = local.enabled ? 1 : 0

  comment = "OAI"
}

#tfsec:ignore:aws-cloudfront-enable-waf
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  count = local.enabled ? 1 : 0

  dynamic "origin" {
    for_each = var.origins

    content {
      domain_name = origin.value.s3_origin.enabled ? origin.value.s3_origin.bucket_domain_name : origin.value.domain_name
      origin_id   = origin.value.id

      dynamic "custom_origin_config" {
        for_each = !origin.value.s3_origin.enabled ? toset([origin.value]) : []

        content {
          http_port              = origin.value.http_port
          https_port             = origin.value.https_port
          origin_read_timeout    = 60
          origin_protocol_policy = "match-viewer"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin.enabled ? toset([var.origins.s3_origin.bucket_domain_name]) : []

        content {
          origin_access_identity = one(aws_cloudfront_origin_access_identity.oai[*].cloudfront_access_identity_path)
        }
      }
    }
  }

  enabled             = local.enabled
  is_ipv6_enabled     = true
  aliases             = var.route53_domain_names
  default_root_object = "index.html"

  dynamic "logging_config" {
    for_each = var.logs_bucket_domain_name != "" ? toset([var.logs_bucket_domain_name]) : []

    content {
      include_cookies = false
      bucket          = logging_config.value #tfsec:ignore:aws-cloudfront-enable-logging
      prefix          = "log/cloudfront/"
    }
  }

  dynamic "default_cache_behavior" {
    for_each = { for k, v in var.origins : k => v.id if v.cache.default }

    content {
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = default_cache_behavior.value

      forwarded_values {
        query_string = false

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = true

      response_headers_policy_id = one(aws_cloudfront_response_headers_policy.web_security_headers_policy[*].id)

      function_association {
        event_type   = "viewer-request"
        function_arn = one(aws_cloudfront_function.sub_folder_routing[*].arn)
      }
    }
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn            = lookup(var.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(var.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(var.viewer_certificate, "iam_certificate_id", null)

    minimum_protocol_version = lookup(var.viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method       = lookup(var.viewer_certificate, "ssl_support_method", null)
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 200
    response_page_path    = "/404.html"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_function" "sub_folder_routing" {
  count = local.enabled ? 1 : 0

  name    = "${local.name}-cloudfront_sub_folder_routing"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("${path.module}/files/cloudfront_sub_folder_routing.js")
}

resource "aws_cloudfront_response_headers_policy" "web_security_headers_policy" {
  count = local.enabled ? 1 : 0

  name = "${local.name}-web-security-headers-policy"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    strict_transport_security {
      access_control_max_age_sec = "63072000"
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    # TODO: should really try to remove unsafe-inline from the CSP
    content_security_policy {
      content_security_policy = "frame-ancestors 'none'; connect-src 'self'; default-src 'none'; font-src 'self' fonts.gstatic.com; img-src 'self' data:; media-src 'self'; manifest-src 'self'; script-src 'self' code.jquery.com 'unsafe-inline'; style-src 'self' fonts.googleapis.com 'unsafe-inline';"
      override                = true
    }
  }
}

data "aws_iam_policy_document" "web_resources_policy_document" {
  for_each = { for k, v in var.origins : k => v.s3_origin.bucket_arn if v.s3_origin.enabled }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${each.value}/*"]

    principals {
      type        = "AWS"
      identifiers = [one(aws_cloudfront_origin_access_identity.oai[*].iam_arn)]
    }
  }
}

resource "aws_s3_bucket_policy" "web_resources_policy" {
  for_each = { for k, v in var.origins : k => v.s3_origin.bucket_id if v.s3_origin.enabled }

  bucket = each.value
  policy = data.aws_iam_policy_document.web_resources_policy_document[each.key].json
}

resource "aws_route53_record" "cloudfront_distribution" {
  count = local.enabled && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = one(aws_cloudfront_distribution.cloudfront_distribution[*].domain_name)
    zone_id                = one(aws_cloudfront_distribution.cloudfront_distribution[*].hosted_zone_id)
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_cloudfront_distribution" {
  count = local.enabled && var.apex_dns_zone_id != "" ? 1 : 0

  zone_id = var.apex_dns_zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = one(aws_cloudfront_distribution.cloudfront_distribution[*].domain_name)
    zone_id                = one(aws_cloudfront_distribution.cloudfront_distribution[*].hosted_zone_id)
    evaluate_target_health = false
  }
}