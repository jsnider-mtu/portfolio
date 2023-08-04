data "aws_vpc" "vpc_id" {
  count = var.enable ? 1 : 0

  tags = {
    Environment = var.env
  }
}

data "aws_subnet_ids" "private-subnets" {
  count = var.enable ? 1 : 0

  vpc_id = data.aws_vpc.vpc_id[count.index].id

  tags = {
    Environment = var.env
    Component   = var.component
  }
}

data "aws_subnet_ids" "public-subnets" {
  count = var.enable ? 1 : 0

  vpc_id = data.aws_vpc.vpc_id[count.index].id

  tags = {
    Environment = var.env
    Component   = "network"
  }
}

data "aws_caller_identity" "current" {
  count = var.enable ? 1 : 0
}

data "aws_eks_cluster" "eks_cluster" {
  count = var.enable ? 1 : 0
  name  = var.cluster_name
}
