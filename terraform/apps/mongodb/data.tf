data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu18" {
  most_recent = true
  owners      = ["099720109477"] # AWS

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-arm64-server-*"]
  }
}

data "aws_vpc" "default" {
  cidr_block = "172.30.0.0/16"
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}