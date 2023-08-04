output "cluster_name" {
  value       = concat(aws_eks_cluster.cluster.*.name, [""])[0]
  description = "Cluster name"
}

output "node_role" {
  value       = concat(aws_iam_role.node.*.name, [""])[0]
  description = "IAM Role which has the required policies to add the node to the cluster."
}

output "node_role_arn" {
  value       = concat(aws_iam_role.node.*.arn, [""])[0]
  description = "IAM Role ARN which has the required policies to add the node to the cluster."
}

output "cluster_security_group" {
  value       = concat(aws_security_group.cluster.*.id, [""])[0]
  description = "Security Group between cluster and nodes."
}

output "node_security_group" {
  value       = concat(aws_security_group.node.*.id, [""])[0]
  description = "Security Group to be able to access to the Kubernetes Control Plane and other nodes."
}

output "node_instance_profile" {
  value       = concat(aws_iam_instance_profile.node.*.name, [""])[0]
  description = "IAM Instance Profile which has the required policies to add the node to the cluster."
}

output "node_instance_profile_arn" {
  value       = concat(aws_iam_instance_profile.node.*.arn, [""])[0]
  description = "IAM Instance Profile ARN which has the required policies to add the node to the cluster."
}

output "cluster_kms_key_id" {
  value       = module.kms.kms_key_id
  description = "For use in cluster node EBS drive encryption"
}

output "cluster_kms_key_arn" {
  value       = module.kms.kms_key_arn
  description = "For use in cluster node EBS drive encryption"
}
