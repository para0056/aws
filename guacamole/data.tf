data "aws_vpc" "main" {
 id = var.vpc_id
}

data "aws_subnet" "public1a" {
  id = var.subnet_id
}

data "aws_security_group" "selected" {
  id = var.security_group_id
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}
