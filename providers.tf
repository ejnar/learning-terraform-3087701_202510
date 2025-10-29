terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 7.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
}  