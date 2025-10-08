variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "techchallenge-eks"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default = "terraform-kajgfkafvbajbfkagfskahgdfiahfkds"
}

# Application Configuration
variable "image" {
  description = "Docker image da API"
  type        = string
  default     = "techchallengegestorpedidos-server-back:latest"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "database_url" {
  description = "Connection string do banco"
  type        = string
  sensitive   = true
  default     = ""
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
