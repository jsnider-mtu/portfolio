data "aws_vpc" "vpc_id" {
  tags = {
    Environment = var.env
  }
}

data "aws_subnet_ids" "subnet" {
  vpc_id = data.aws_vpc.vpc_id.id

  tags = {
    Environment = var.env
    Component   = var.component
  }
}
