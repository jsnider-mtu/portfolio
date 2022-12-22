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

variable "capacity_type" {
  type        = string
  default     = "ON_DEMAND"
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT.   Terraform will only perform drift detection if a configuration value is provided."
}

variable "enable" {
  type    = bool
  default = true
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "component" {
  type        = string
  description = "Purpose for cluster"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name provided when the cluster was created."
}

variable "instance_type" {
  type        = string
  default     = null
  description = "EC2 instance type for the node instances."
}

variable "enable_instance_requirements" {
  type        = bool
  default     = false
  description = "Use instance_requirements instead of instance_type; for spot instances mostly."
}

variable "instance_requirements_memory_mib" {
  type        = number
  default     = 1
  description = "Memory in Mib."
}

variable "instance_requirements_vcpu_count" {
  type        = number
  default     = 1
  description = "VCPU count."
}

variable "node_min_size" {
  default     = 1
  description = "Minimum size of Node Group ASG."
}

variable "node_max_size" {
  default     = 2
  description = "Maximum size of Node Group ASG."
}

variable "ec2_ssh_key" {
  default     = ""
  description = "The EC2 Key Pair to allow SSH access to the instances."
}

variable "security_groups" {
  type        = list(string)
  description = "The security groups assigned to the worker nodes."
}

variable "disk_size" {
  description = "The size of the volume in gigabytes"
}

variable "group_name" {
  type        = string
  description = "Name of node group"
}

variable "desired_capacity" {
  type        = number
  description = "The number of Amazon EC2 instances that should be running in the group."
}

variable "kube_labels" {
  type        = map(string)
  description = "Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  default     = {}
}

variable "kube_version" {
  type        = string
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided"
  default     = null
  validation {
    condition = (
      length(compact([var.kube_version])) == 0 ? true : length(regexall("^\\d+\\.\\d+$", var.kube_version)) == 1
    )
    error_message = "Var kube_version, if supplied, must be like \"1.16\" (no patch level)."
  }
}
variable "ami_release_version" {
  type        = string
  description = "EKS AMI version to use, e.g. \"1.16.13-20200821\" (no \"v\"). Defaults to latest version for Kubernetes version."
  default     = null
}

variable "user_data" {
  default     = ""
  description = "Additional user data used when bootstrapping the EC2 instance."
}

variable "instance_profile" {
  type        = string
  description = "IAM Instance Profile which has the required policies to add the node to the cluster."
}

variable "ami_type" {
  type        = string
  default     = "AL2_x86_64"
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group."
}

variable "node_role_arn" {
  type        = string
  description = "Amazon Resource Name (ARN) of the IAM Role that provides permissions for the EKS Node Group."
}

variable "subnet_ids" {
  type        = list(any)
  default     = []
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: kubernetes.io/cluster/CLUSTER_NAME"
}

variable "force_update_version" {
  type        = bool
  default     = false
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue."
}

variable "kms_key_id" {
  description = "KMS Key for encrypting root volumes."
}

variable "create_timeout" {
  default = "2h"
}

variable "delete_timeout" {
  default = "2h"
}

variable "update_timeout" {
  default = "2h"
}

variable "volume_type" {
  type        = string
  default     = "gp2"
  description = "The type of volume."
}

variable "ami_image_id" {
  type        = string
  description = "AMI to use. Ignored of `launch_template_id` is supplied."
  default     = null
}

variable "enable_monitoring" {
  default = true
}

variable "enable_multus_eni" {
  default = false
}

variable "enable_imdsv2" {
  type        = bool
  description = "restrict access to instance metadata by require authentication"
  default     = false
}

variable "max_unavailable_percentage" {
  description = "Desired max percentage of unavailable worker nodes during node group update."
  default     = 50
}

