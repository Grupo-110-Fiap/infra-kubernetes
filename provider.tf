terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.15.0"
    }



    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "terraform-kajgfkafvbajbfkagfskahgdfiahfkds"
    key    = "techchallenge/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TechChallenge"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}



