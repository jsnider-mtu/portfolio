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
    Component   = "eks"
  }
}

data "aws_subnet_ids" "public-subnets" {
  count = var.enable ? 1 : 0

  vpc_id = data.aws_vpc.vpc_id[count.index].id

  tags = {
    Environment = var.env
    Component   = "network"
    eks_master  = "1"
  }
}

data "aws_caller_identity" "current" {}
data "aws_eks_cluster" "eks_cluster" {
  count = var.enable ? 1 : 0

  name       = var.name
  depends_on = [aws_eks_cluster.cluster]
}

data "aws_region" "current" {}

