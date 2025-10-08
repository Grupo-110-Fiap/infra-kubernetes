# Data sources
data "aws_caller_identity" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-public"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# ECR Repository
resource "aws_ecr_repository" "pedidos_api" {
  name                 = "techchallenge/pedidos-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "PostgreSQL access from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres-v2" {
  identifier = "${var.cluster_name}-postgres"

  engine         = "postgres"
  engine_version = "17.5"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "gestor_pedidos_db"
  username = "fiap_arch"
  password = "fiap_arch"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Explicitly ensure RDS is not publicly accessible
  publicly_accessible = true

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-postgres"
  }
}

# ConfigMap
resource "kubernetes_config_map" "pedidos_config" {
  metadata {
    name      = "pedidos-config"
    namespace = kubernetes_namespace.pedidos.metadata[0].name
  }
  data = {
    DB_TYPE = "postgres"
    APP_ENV = "dev"
    GIN_MODE = "release"
  }

  depends_on = [aws_eks_node_group.main]
}

# Namespace
resource "kubernetes_namespace" "pedidos" {
  metadata {
    name = "pedidos"
  }

  depends_on = [aws_eks_node_group.main]
}

# Secret
resource "kubernetes_secret" "pedidos_secret" {
  metadata {
    name      = "pedidos-secret"
    namespace = kubernetes_namespace.pedidos.metadata[0].name
  }
  data = {
    DATABASE_URL = base64encode("postgresql://fiap_arch:fiap_arch@${aws_db_instance.postgres-v2.endpoint}/@${aws_db_instance.postgres-v2.db_name}")
  }
  type = "Opaque"

  depends_on = [aws_eks_node_group.main]
}

# Deployment
resource "kubernetes_deployment" "pedidos_api" {
  metadata {
    name      = "pedidos-api"
    namespace = kubernetes_namespace.pedidos.metadata[0].name
    labels    = { app = "pedidos-api" }
  }

  spec {
    replicas = 1

    selector { match_labels = { app = "pedidos-api" } }

    template {
      metadata {
        labels = { app = "pedidos-api" }
      }

      spec {
        container {
          name  = "pedidos-api"
          image = "${aws_ecr_repository.pedidos_api.repository_url}:${var.image_tag}"

          port { container_port = 8080 }

          env_from {
            config_map_ref { name = kubernetes_config_map.pedidos_config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret.pedidos_secret.metadata[0].name }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
                path = "/healthz"
                port = 8081
                }
            initial_delay_seconds = 30
            period_seconds        = 10000
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path = "/readyz"
              port = 8081
            }
            initial_delay_seconds = 5
            period_seconds        = 10000
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# Service
resource "kubernetes_service" "pedidos_service" {
  metadata {
    name      = "pedidos-api"
    namespace = kubernetes_namespace.pedidos.metadata[0].name
  }
  spec {
    selector = { app = kubernetes_deployment.pedidos_api.metadata[0].labels.app }
    type     = "LoadBalancer"
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# HPA (v2)
resource "kubernetes_horizontal_pod_autoscaler_v2" "pedidos_hpa" {
  metadata {
    name      = "pedidos-api-hpa"
    namespace = kubernetes_namespace.pedidos.metadata[0].name
  }
  spec {
    min_replicas = 1
    max_replicas = 2
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.pedidos_api.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.main]
}