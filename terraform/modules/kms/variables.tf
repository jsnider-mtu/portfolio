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

variable "name" {
  description = "The display name of the alias. The name must start with the word \"alias\" followed by a forward slash (alias/)"
}

variable "policy" {
  description = "The path of the policy in IAM"
  type        = string
  default     = ""
}

variable "enable" {
  type    = bool
  default = true
}

variable "key_usage" {
  default     = "ENCRYPT_DECRYPT"
  description = "Specifies the intended use of the key. Valid values: ENCRYPT_DECRYPT or SIGN_VERIFY."
}

variable "customer_master_key_spec" {
  default = "SYMMETRIC_DEFAULT"
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports."
}

variable "is_enabled" {
  type = bool
  default = true
  description = "Specifies whether the key is enabled."
}
