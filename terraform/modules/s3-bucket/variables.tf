variable "bucket_name" {
}

variable "stage" {
}

variable "env" {
}

variable "tags_context" {
  type = object({
    enabled             = bool
    name                = string
    namespace           = string
    environment         = string
    stage               = string
    attributes          = list(string)
    tags                = map(string)
    delimiter           = string
    label_order         = list(string)
    regex_replace_chars = string
    additional_tag_map  = map(string)
  })
  description = "Context map generated by terraform-null-label module"
}

variable "acl" {
  default = "private"
}

variable "versioning_enabled" {
  default = false
}

variable "custom_bucket_policy" {
  default = false
}

variable "custom_bucket_policy_doc" {
  default     = ""
  description = "Provide bucket policy in HEREDOC syntax"
}

locals {
  default_bucket_policy_doc = <<EOT
{
    "Version": "2012-10-17",
    "Id": "SSLOnlyPolicy",
    "Statement": [
        {
            "Sid": "AllowSSLRequestsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.this_bucket[0].arn}",
                "${aws_s3_bucket.this_bucket[0].arn}/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOT
}

variable "ignore_public_acls" {
  default     = true
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
}

variable "block_public_acls" {
  default     = true
  description = "Whether Amazon S3 should block public ACLs for this bucket."
}

variable "block_public_policy" {
  default     = true
  description = "Whether Amazon S3 should block public bucket policies for this bucket."
}

variable "restrict_public_buckets" {
  default     = true
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
}

variable "index_document" {
  default     = ""
  description = "Index document for S3 website"
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms."
}

variable "lifecycle_rule" {
  description = "List of maps containing configuration of object lifecycle management."
  type        = any
  default     = []
}

variable "create_bucket" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = true
}

variable "aws_s3_kms_key_arn" {
  type = string
}
