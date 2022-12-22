module "label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

resource "aws_s3_bucket" "this_bucket" {
  bucket = "jsnider-mtu-${var.env}-${var.bucket_name}"
  acl    = var.acl
  count  = var.create_bucket ? 1 : 0
  tags   = module.label.tags


  logging {
    target_bucket = "jsnider-mtu-${var.stage}-s3-logs"
    target_prefix = var.bucket_name
  }

  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle {
    ignore_changes = [cors_rule]
  }

  dynamic "website" {
    for_each = var.index_document == "" ? [] : [var.index_document]
    content {
      index_document = var.index_document
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule

    content {
      id                                     = lookup(lifecycle_rule.value, "id", null)
      prefix                                 = lookup(lifecycle_rule.value, "prefix", null)
      tags                                   = lookup(lifecycle_rule.value, "tags", null)
      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)
      enabled                                = lifecycle_rule.value.enabled

      # Max 1 block - expiration
      dynamic "expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "expiration", {})]

        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      # Several blocks - transition
      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])

        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      # Max 1 block - noncurrent_version_expiration
      dynamic "noncurrent_version_expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "noncurrent_version_expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "noncurrent_version_expiration", {})]

        content {
          days = lookup(noncurrent_version_expiration.value, "days", null)
        }
      }

      # Several blocks - noncurrent_version_transition
      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", [])

        content {
          days          = lookup(noncurrent_version_transition.value, "days", null)
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.aws_s3_kms_key_arn
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this_bucket_policy" {
  count      = var.custom_bucket_policy ? 1 : 0
  bucket     = aws_s3_bucket.this_bucket[count.index].id
  policy     = var.custom_bucket_policy_doc
  depends_on = [aws_s3_bucket.this_bucket]
}

resource "aws_s3_bucket_policy" "default_bucket_policy" {
  count      = var.custom_bucket_policy ? 0 : 1
  bucket     = aws_s3_bucket.this_bucket[count.index].id
  policy     = local.default_bucket_policy_doc
  depends_on = [aws_s3_bucket.this_bucket]
}

resource "aws_s3_bucket_public_access_block" "this_access_block" {
  count                   = var.create_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.this_bucket[count.index].id
  ignore_public_acls      = var.ignore_public_acls
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

