module "label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

data "aws_caller_identity" "current" {}

data "template_file" "default" {
  count    = var.enable_s3 && var.enable ? 1 : 0
  template = concat(data.aws_iam_policy_document.origin.*.json, [""])[0]

  vars = {
    origin_path = var.s3_origin_id_path_override == null ? coalesce(var.s3_path_pattern, "/") : var.s3_origin_id_path_override
    bucket_name = var.s3_bucket_name
  }
}

data "aws_s3_bucket" "selected" {
  count  = var.create_bucket || var.enable_s3 == false ? 0 : 1
  bucket = var.s3_bucket_name
}

resource "aws_cloudfront_origin_access_identity" "default" {
  count   = var.s3_bucket_name != "" && var.enable && var.s3_origin_access_identity == "" ? 1 : 0
  comment = "${var.s3_bucket_name}-access-id"
}

data "aws_iam_policy_document" "origin" {
  count = var.enable_s3 && var.enable && var.s3_origin_access_identity == "" ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::$${bucket_name}$${origin_path}*"]

    principals {
      type        = "AWS"
      identifiers = [concat(aws_cloudfront_origin_access_identity.default.*.iam_arn, [""])[0]]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::$${bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = [concat(aws_cloudfront_origin_access_identity.default.*.iam_arn, [""])[0]]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_cloudfront_access" {
  count = var.enable_s3 == false || var.s3_acl == "public-read" || var.enable == false || var.s3_origin_access_identity != "" ? 0 : 1

  bucket = var.create_bucket ? aws_s3_bucket.origin[count.index].id : var.s3_bucket_name
  policy = data.template_file.default[count.index].rendered
}

module "bucket_label" {
  source  = "cloudposse/label/null"
  context = module.label.context
  name    = "${module.label.name}-bucket"
}

resource "aws_s3_bucket" "origin" {
  count = var.create_bucket ? 1 : 0

  bucket = var.s3_bucket_name
  tags   = module.bucket_label.tags

  lifecycle {
    ignore_changes = [lifecycle_rule]
  }
  dynamic "website" {
    for_each = var.index_document == "" ? [] : [var.index_document]
    content {
      index_document = var.index_document
    }
  }

  dynamic "website" {
    for_each = var.redirect_all_requests_to == "" ? [] : [var.redirect_all_requests_to]
    content {
      redirect_all_requests_to = var.redirect_all_requests_to
    }
  }
}


resource "aws_s3_bucket_logging" "origin_bucket_logging" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.origin[count.index].id

  target_bucket = "jsnider-mtu-${var.stage}-s3-logs"
  target_prefix = var.s3_bucket_name
}

resource "aws_s3_bucket_acl" "origin_bucket_acl" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.origin[count.index].id
  acl    = var.s3_acl
}

resource "aws_s3_bucket_cors_configuration" "origin_cors_configuration" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.origin[count.index].id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }

}


resource "aws_s3_bucket_server_side_encryption_configuration" "origin_bucket_encryption" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.origin[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
module "cloudfront_label" {
  source  = "cloudposse/label/null"
  context = module.label.context
  name    = "${module.label.name}-cloudfront"
}

resource "aws_cloudfront_distribution" "this_distro" {
  count = var.enable ? 1 : 0

  depends_on          = [aws_s3_bucket.origin]
  enabled             = true
  is_ipv6_enabled     = var.is_ipv6_enabled
  aliases             = var.domains
  web_acl_id          = var.web_acl_id
  price_class         = var.price_class
  default_root_object = var.index_document
  wait_for_deployment = var.wait_for_deployment
  http_version        = var.http_version
  tags                = module.cloudfront_label.tags

  dynamic "origin" {
    for_each = var.aws_lb == null ? [] : [var.aws_lb]
    content {
      domain_name = var.domain_name == null ? var.aws_lb : var.domain_name
      origin_id   = var.origin_id == null ? var.aws_lb : var.origin_id
      origin_path = var.origin_path

      custom_header {
        name  = var.custom_header
        value = "6gEIkhSYS7a7"
      }

      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2", "TLSv1.1"]
        origin_keepalive_timeout = var.keepalive_timeout
        origin_read_timeout      = var.origin_timeout
      }
    }
  }

  dynamic "origin" {
    for_each = var.enable_s3 == false ? var.create_bucket == false ? [] : [concat(data.aws_s3_bucket.selected.*.bucket_domain_name, [""])[0]] : [concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]]
    content {
      domain_name = var.create_bucket == false ? concat(data.aws_s3_bucket.selected.*.bucket_domain_name, [""])[0] : var.redirect_all_requests_to == "" ? concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0] : concat(aws_s3_bucket.origin.*.website_endpoint, [""])[0]
      origin_id   = var.create_bucket == false ? concat(data.aws_s3_bucket.selected.*.bucket_domain_name, [""])[0] : concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]
      origin_path = var.origin_path
      dynamic "s3_origin_config" {
        for_each = var.redirect_all_requests_to == "" ? [var.redirect_all_requests_to] : []
        content {
          origin_access_identity = var.s3_origin_access_identity == "" ? concat(aws_cloudfront_origin_access_identity.default.*.cloudfront_access_identity_path, [""])[0] : var.s3_origin_access_identity
        }
      }

      dynamic "custom_origin_config" {
        for_each = var.redirect_all_requests_to == "" ? [] : [var.redirect_all_requests_to]
        content {
          http_port                = 80
          https_port               = 443
          origin_protocol_policy   = "http-only"
          origin_ssl_protocols     = ["TLSv1.2", "TLSv1.1"]
          origin_keepalive_timeout = var.keepalive_timeout
          origin_read_timeout      = var.origin_timeout
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    # cache_policy_id          = var.default_cache_policy_id
    # origin_request_policy_id = var.default_origin_request_policy_id
    target_origin_id         = var.origin_id == null ? (var.enable_s3 == false || var.aws_lb != null ? var.aws_lb : concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]) : var.origin_id
    compress                 = var.compress

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forward_headers

      cookies {
        forward = var.forward_cookies
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    realtime_log_config_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:realtime-log-config/cloudfront-all"
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_s3 == false ? var.s3_path_pattern == "" ? [] : [var.s3_path_pattern] : [concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]]
    content {
      path_pattern     = var.s3_path_pattern
      allowed_methods  = var.s3_allowed_methods
      cached_methods   = var.s3_cached_methods
      target_origin_id = var.create_bucket == false ? concat(data.aws_s3_bucket.selected.*.bucket_domain_name, [""])[0] : concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]

      forwarded_values {
        query_string = var.s3_forward_query_string
        headers      = var.s3_forward_headers

        cookies {
          forward = "none"
        }
      }

      #min_ttl                = 0
      #default_ttl            = 86400
      #max_ttl                = 31536000
      compress               = true
      viewer_protocol_policy = "redirect-to-https"

      realtime_log_config_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:realtime-log-config/cloudfront-all"
    }
  }

  dynamic "origin" {
    for_each = [for i in var.dynamic_custom_origin_config : {
      name                     = i.domain_name
      id                       = i.origin_id
      path                     = lookup(i, "origin_path", null)
      http_port                = i.http_port
      https_port               = i.https_port
      origin_keepalive_timeout = i.origin_keepalive_timeout
      origin_read_timeout      = i.origin_read_timeout
      origin_protocol_policy   = i.origin_protocol_policy
      origin_ssl_protocols     = i.origin_ssl_protocols
      custom_header            = lookup(i, "custom_header", null)
    }]
    content {
      domain_name = origin.value.name
      origin_id   = origin.value.id
      origin_path = origin.value.path
      dynamic "custom_header" {
        for_each = origin.value.custom_header == null ? [] : [for i in origin.value.custom_header : {
          name  = i.name
          value = i.value
        }]
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
      custom_origin_config {
        http_port                = origin.value.http_port
        https_port               = origin.value.https_port
        origin_keepalive_timeout = origin.value.origin_keepalive_timeout
        origin_read_timeout      = origin.value.origin_read_timeout
        origin_protocol_policy   = origin.value.origin_protocol_policy
        origin_ssl_protocols     = origin.value.origin_ssl_protocols
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.dynamic_ordered_cache_behavior
    iterator = cache_behavior
    content {
      path_pattern             = cache_behavior.value.path_pattern
      allowed_methods          = cache_behavior.value.allowed_methods
      cache_policy_id          = cache_behavior.value.cache_policy_id
      origin_request_policy_id = cache_behavior.value.origin_request_policy_id
      cached_methods           = cache_behavior.value.cached_methods
      target_origin_id         = cache_behavior.value.target_origin_id
      compress                 = lookup(cache_behavior.value, "compress", null)

      viewer_protocol_policy = cache_behavior.value.viewer_protocol_policy

      realtime_log_config_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:realtime-log-config/cloudfront-all"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    ssl_support_method       = var.ssl_support_method
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = var.minimum_protocol_version
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }
  lifecycle {
    ignore_changes = [restrictions]
  }
}

resource "aws_shield_protection" "cf_shield_protection" {
  count        = var.enable ? (module.cloudfront_label.environment == "production" ? 1 : 0) : 0
  name         = aws_cloudfront_distribution.this_distro[0].domain_name
  resource_arn = aws_cloudfront_distribution.this_distro[0].arn
}

resource "aws_cloudwatch_metric_alarm" "ddos_alarm" {
  count               = var.enable ? (module.cloudfront_label.environment == "production" ? 1 : 0) : 0
  alarm_name          = "DDoSDetectedAlarmForProtection_${aws_cloudfront_distribution.this_distro[0].id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 20
  treat_missing_data  = "notBreaching"
  threshold           = 1
  datapoints_to_alarm = 1
  period              = 60
  statistic           = "Sum"
  alarm_description   = "Alarm for DDoS events detected on resource ${aws_cloudfront_distribution.this_distro[0].arn}"
  namespace           = "AWS/DDoSProtection"
  metric_name         = "DDoSDetected"
  dimensions = {
    "ResourceArn" = aws_cloudfront_distribution.this_distro[0].arn
  }
  depends_on    = [aws_shield_protection.cf_shield_protection]
  alarm_actions = ["arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:EC2-Slack-Alerting"]
}
