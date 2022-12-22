resource "aws_eks_cluster" "cluster" {
  count = var.enable ? 1 : 0

  name                      = var.name
  version                   = var.kube_version
  role_arn                  = aws_iam_role.cluster[count.index].arn
  enabled_cluster_log_types = var.log_types


  vpc_config {
    subnet_ids              = flatten([data.aws_subnet_ids.private-subnets[count.index].ids, data.aws_subnet_ids.public-subnets[count.index].ids])
    security_group_ids      = [aws_security_group.cluster[count.index].id]
    endpoint_private_access = var.enable_private_access
    endpoint_public_access  = var.enable_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  dynamic "encryption_config" {
    for_each = var.secrets_kms_arn
    content {
      resources = ["secrets"]
      provider {
        key_arn = encryption_config.value
      }
    }
  }
}



resource "aws_cloudwatch_log_group" "eks_logs" {
  count             = length(var.log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.log_retention_in_days
}

resource "aws_eks_addon" "vpc_cni" {
  count         = var.cni_version == "" ? 0 : 1
  depends_on    = [aws_eks_cluster.cluster]
  cluster_name  = var.name
  addon_name    = "vpc-cni"
  addon_version = var.cni_version
}

resource "aws_eks_addon" "kube_proxy" {
  count         = var.kubeproxy_version == "" ? 0 : 1
  depends_on    = [aws_eks_cluster.cluster]
  cluster_name  = var.name
  addon_name    = "kube-proxy"
  addon_version = var.kubeproxy_version
}

resource "aws_eks_addon" "core_dns" {
  count         = var.coredns_version == "" ? 0 : 1
  depends_on    = [aws_eks_cluster.cluster]
  cluster_name  = var.name
  addon_name    = "coredns"
  addon_version = var.coredns_version
}

