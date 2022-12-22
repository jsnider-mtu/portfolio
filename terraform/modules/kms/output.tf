output "kms_key_arn" {
  value = concat(aws_kms_key.a.*.arn, [""])[0]
}

output "kms_key_id" {
  value = concat(aws_kms_key.a.*.key_id, [""])[0]
}

