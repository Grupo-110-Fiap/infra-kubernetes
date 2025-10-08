output "service_url" {
  description = "Endpoint local da API"
  value       = "http://localhost:8081"
}

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

# RDS Outputs
output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgres-v2.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres-v2.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.postgres-v2.username
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.postgres-v2.db_name
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

# Load Balancer Output
output "load_balancer_hostname" {
  description = "Load balancer hostname"
  value       = kubernetes_service.pedidos_service.status.0.load_balancer.0.ingress.0.hostname
  depends_on  = [kubernetes_service.pedidos_service]
}
