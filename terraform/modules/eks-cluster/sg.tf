#Cluster Security Group
module "sg_label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
  name    = "${var.name}-eks-cluster-security-group"
}

resource "aws_security_group" "cluster" {
  count = var.enable ? 1 : 0

  name        = var.name
  description = "Cluster communication with worker nodes"
  vpc_id      = data.aws_vpc.vpc_id[count.index].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.sg_label.tags
}

resource "aws_security_group_rule" "office-network" {
  count = var.enable == true && length(var.access_ips) != 0 ? 1 : 0

  description       = "Allow access_ips to communicate with the cluster API Server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster[count.index].id
  cidr_blocks       = var.access_ips
}

resource "aws_security_group_rule" "cluster-ingress-cluster-https" {
  count = var.enable ? 1 : 0

  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster[count.index].id
  source_security_group_id = aws_security_group.node[count.index].id
}

#Node Security Group
module "node_sg_label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
  name    = "${var.name}-eks-node-security-group"

  tags = {
    "kubernetes.io/cluster/${var.name}" = "owned"
  }
}

resource "aws_security_group" "node" {
  count = var.enable ? 1 : 0

  name        = "${var.name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = data.aws_vpc.vpc_id[count.index].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.node_sg_label.tags

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "node_ingress_self" {
  count = var.enable ? 1 : 0

  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node[count.index].id
  source_security_group_id = aws_security_group.node[count.index].id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  count = var.enable ? 1 : 0

  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node[count.index].id
  source_security_group_id = aws_security_group.cluster[count.index].id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  count = var.enable ? 1 : 0

  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node[count.index].id
  source_security_group_id = aws_security_group.cluster[count.index].id
}

resource "aws_security_group_rule" "node_allow_ssh" {
  count = var.enable == true && length(var.access_ips) != 0 ? 1 : 0

  description       = "The CIDR blocks from which to allow incoming ssh connections to the EKS nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.node[count.index].id
  cidr_blocks       = var.access_ips
  to_port           = 22
  type              = "ingress"
}

