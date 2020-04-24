#* Create VPC *#
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name       = "lse-dev-vpc"
    CostCentre = "TBD"
  }
}

#* Create/reference Route table #*

#* Create Subnets *#
resource "aws_subnet" "app-1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ca-central-1a"
  cidr_block        = var.priv-1a_cidr_block
}

resource "aws_subnet" "app-1b" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ca-central-1a"
  cidr_block        = var.priv-1a_cidr_block
}

resource "aws_subnet" "db-1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ca-central-1a"
  cidr_block        = var.priv-1a_cidr_block
}
resource "aws_subnet" "db-1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ca-central-1a"
  cidr_block        = var.priv-1a_cidr_block
}

#* Create NACLs *#

#* Create SGs *#
