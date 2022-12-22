output "full_bucket_name" {
  value = concat(aws_s3_bucket.this_bucket.*.id, [""])[0]
}

output "full_bucket_arn" {
  value = concat(aws_s3_bucket.this_bucket.*.arn, [""])[0]
}

