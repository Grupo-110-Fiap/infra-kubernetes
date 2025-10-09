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
  default = "terraform-kajgfkafvbajbfkagfskahgdfiahfkds-EKS"
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



# Legacy variables (for backward compatibility - can be removed once tfvars are cleaned up)
variable "db_password" {
  description = "Database password (legacy - will be removed)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "lambda_s3_key" {
  description = "Lambda S3 key (legacy - will be removed)"
  type        = string
  default     = ""
}
