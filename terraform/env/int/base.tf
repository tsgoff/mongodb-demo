terraform {
  backend "s3" {
    region = "eu-west-1"
    key = "mongodb/int.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
  required_version = ">= 0.14"
}
