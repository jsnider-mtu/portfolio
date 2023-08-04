module "label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

resource "aws_kms_key" "a" {
  count = var.enable ? 1 : 0

  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  description              = "${var.name} KMS key"
  enable_key_rotation      = var.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? true : false
  policy                   = var.policy
  is_enabled               = var.is_enabled
  tags                     = module.label.tags
}

resource "aws_kms_alias" "a" {
  count         = var.enable ? 1 : 0
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.a[count.index].key_id
}
