locals {
  user_data = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace
${var.user_data}

--==MYBOUNDARY==--\
USERDATA

  bottlerocket_user_data = <<USERDATA
[settings.kubernetes]
api-server = "${var.enable ? data.aws_eks_cluster.eks_cluster[0].endpoint : ""}"
cluster-certificate = "${var.enable ? data.aws_eks_cluster.eks_cluster[0].certificate_authority[0].data : ""}"
cluster-name = "${var.enable ? data.aws_eks_cluster.eks_cluster[0].id : ""}"
${var.user_data}
USERDATA
}

locals {
  arch_label_map = {
    "AL2_x86_64" : "",
    "AL2_x86_64_GPU" : "-gpu",
    "AL2_ARM_64" : "-arm64",
    "BOTTLEROCKET_x86_64" : "x86_64",
    "BOTTLEROCKET_ARM_64" : "aarch64"
  }

  ami_kind = split("_", var.ami_type)[0]

  ami_format = {
    "AL2" : "amazon-eks%s-node-%s"
    "BOTTLEROCKET" : "bottlerocket-aws-k8s-%s-%s-%s"
  }

  ami_kube_version = var.kube_version

  ami_version_regex = {
    "AL2" : (length(var.ami_release_version) == 1 ?
      replace(var.ami_release_version[0], "/^(\\d+\\.\\d+)\\.\\d+-(\\d+)$/", "$1-v$2") :
    "${local.ami_kube_version}-*"),
    "BOTTLEROCKET" : (length(var.ami_release_version) == 1 ?
    format("v%s", var.ami_release_version[0]) : "*"),
  }

  ami_regex = {
    "AL2" : format(local.ami_format["AL2"], local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_kind]),
    "BOTTLEROCKET" : format(local.ami_format["BOTTLEROCKET"], local.ami_kube_version, local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_kind]),
  }
}

