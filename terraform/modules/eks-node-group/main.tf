module "label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
  name    = "${var.cluster_name}-node"

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "owned"
  }

  additional_tag_map = {
    propagate_at_launch = "true"
  }
}

resource "aws_launch_template" "this_launch_template" {
  count                  = var.enable ? 1 : 0
  name                   = "${var.group_name}-launch-template"
  user_data              = var.ami_type == "BOTTLEROCKET_x86_64" || var.ami_type == "BOTTLEROCKET_ARM_64" ? base64encode(local.bottlerocket_user_data) : base64encode(local.user_data)
  ebs_optimized          = true
  instance_type          = var.enable_instance_requirements ? null : var.instance_type
  key_name               = var.ec2_ssh_key
  vpc_security_group_ids = var.security_groups
  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = module.label.tags
  }

  tag_specifications {
    resource_type = "volume"

    tags = module.label.tags
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = var.volume_type
      volume_size           = var.disk_size
      delete_on_termination = true
      kms_key_id            = var.kms_key_id
      encrypted             = true
    }
  }

  dynamic "monitoring" {
    for_each = var.enable_monitoring ? [""] : []
    content {
      enabled = true
    }
  }

  dynamic "instance_requirements" {
    for_each = var.enable_instance_requirements ? [""] : []

    content {
      memory_mib {
        min = var.instance_requirements_memory_mib
        max = var.instance_requirements_memory_mib
      }
      vcpu_count {
        min = var.instance_requirements_vcpu_count
        max = var.instance_requirements_vcpu_count
      }
      excluded_instance_types = ["g4dn.*, g5.*, im4gn.*, m6g.*, m6gd.*, d3en.*, m5n.*, m5d.*, m5ad.*, m5dn.*, m6i.*, m4.*, h1.*, m6id.*, m5.*"]
      instance_generations    = ["current"]
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 2
    # instance_metadata_tags      = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "generate_kubeconfig" {
  count = var.enable ? 1 : 0
  triggers = {
    ami_release_version = var.ami_release_version
  }
  provisioner "local-exec" {
    command    = "export KUBECONFIG=$HOME/.kube/kubeconfig && /usr/bin/aws eks --region $AWS_REGION update-kubeconfig --name ${var.cluster_name}"
    on_failure = continue
  }
}

resource "null_resource" "scale_down_autoscaler" {
  count      = var.enable ? 1 : 0
  depends_on = [null_resource.generate_kubeconfig[0]]
  triggers = {
    ami_release_version = var.ami_release_version
  }

  provisioner "local-exec" {
    command     = "export KUBECONFIG=$HOME/.kube/kubeconfig && /usr/local/bin/kubectl scale --replicas=0 deployment/cluster-autoscaler -n cluster-autoscaler 2>/dev/null"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

data "aws_ec2_instance_types" "attribute-based" {
  filter {
    name   = "vcpu-info.default-vcpus"
    values = [var.instance_requirements_vcpu_count]
  }
  filter {
    name   = "memory-info.size-in-mib"
    values = [var.instance_requirements_memory_mib]
  }
  filter {
    name   = "processor-info.supported-architecture"
    values = ["x86_64"]
  }
}

resource "aws_eks_node_group" "nodes" {
  count = var.enable ? 1 : 0

  cluster_name         = var.cluster_name
  node_group_name      = var.group_name
  node_role_arn        = var.node_role_arn
  subnet_ids           = length(var.subnet_ids) < 1 ? data.aws_subnet_ids.private-subnets[count.index].ids : var.subnet_ids
  ami_type             = var.ami_type
  labels               = var.kube_labels
  release_version      = var.ami_release_version
  version              = var.kube_version
  force_update_version = var.force_update_version
  capacity_type        = var.capacity_type
  depends_on           = [null_resource.scale_down_autoscaler[0]]

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
    update = var.update_timeout
  }

  launch_template {
    id      = aws_launch_template.this_launch_template[0].id
    version = aws_launch_template.this_launch_template[0].latest_version
  }

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }


  lifecycle {
    create_before_destroy = false
    ignore_changes        = [scaling_config[0].desired_size]
  }

}

resource "null_resource" "scale_up_autoscaler" {
  count      = var.enable ? 1 : 0
  depends_on = [aws_eks_node_group.nodes]
  triggers = {
    ami_release_version = var.ami_release_version
  }

  provisioner "local-exec" {
    command     = "export KUBECONFIG=$HOME/.kube/kubeconfig && /usr/local/bin/kubectl scale --replicas=1 deployment/cluster-autoscaler -n cluster-autoscaler 2>/dev/null"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

