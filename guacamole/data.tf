data "aws_vpc" "main" {
 id = var.vpc_id
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.main.id
}
