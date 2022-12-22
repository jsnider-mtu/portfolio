output "domain" {
  value = concat(aws_cloudfront_distribution.this_distro.*.domain_name, [""])[0]
}

output "hosted_zone_id" {
  value = concat(aws_cloudfront_distribution.this_distro.*.hosted_zone_id, [""])[0]
}

output "bucket_id" {
  value = concat(aws_s3_bucket.origin.*.id, [""])[0]
}

output "bucket_domain" {
  value = concat(aws_s3_bucket.origin.*.bucket_domain_name, [""])[0]
}

output "cf_dist_id" {
  value = concat(aws_cloudfront_distribution.this_distro.*.id, [""])[0]
}

output "cf_dist_arn" {
  value = concat(aws_cloudfront_distribution.this_distro.*.arn, [""])[0]
}

output "s3_origin_access_identity_path" {
  value = concat(aws_cloudfront_origin_access_identity.default.*.cloudfront_access_identity_path, [""])[0]
}
