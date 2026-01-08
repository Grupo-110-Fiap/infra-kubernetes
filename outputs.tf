

# EKS Cluster Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# Node Group Outputs
output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.main.arn
}

# ECR Repository Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.pedidos_api.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.pedidos_api.arn
}



# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC where the cluster and workers are deployed"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "order_upsert_sns_topic_arn" {
  description = "ARN of the SNS topic for order upsert events"
  value       = aws_sns_topic.order_upsert.arn
}

output "order_upsert_sns_topic_name" {
  description = "Name of the SNS topic for order upsert events"
  value       = aws_sns_topic.order_upsert.name
}
