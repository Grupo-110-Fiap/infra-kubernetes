# Arquivo: vpc.tf

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2 # Duas sub-redes para alta disponibilidade
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, 2 + count.index)
  availability_zone = ["us-east-1a", "us-east-1b"][count.index] # Adapte para sua região
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone = ["us-east-1a", "us-east-1b"][count.index] # Adapte para sua região
  tags = {
    Name = "eks-private-subnet-${count.index + 1}"
  }
}

# ... (Configuração adicional de Internet Gateway, NAT Gateway e Route Tables) ...
# Para simplificar, o módulo oficial do EKS cuida disso para você (veja no final).