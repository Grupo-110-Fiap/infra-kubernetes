# TechChallenge - Infraestrutura AWS

Este projeto provisiona a infraestrutura AWS necessária para o TechChallenge, incluindo:

## Recursos Provisionados

### Rede (VPC)
- VPC com CIDR configurável
- Subnets públicas e privadas em múltiplas AZs
- Internet Gateway
- NAT Gateways para conectividade das subnets privadas
- Route Tables e associações

### EKS (Kubernetes)
- Cluster EKS gerenciado
- Node Group com instâncias t3.small
- Roles IAM para cluster e nodes
- Security Groups
- Add-ons necessários (VPC CNI)

### ECR (Container Registry)
- Repositório ECR para as imagens Docker da aplicação

## Uso

1. Configure suas credenciais AWS
2. Copie `terraform.tfvars.example` para `terraform.tfvars` e ajuste os valores
3. Execute:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Outputs Importantes

Este projeto exporta informações importantes que podem ser usadas por outros projetos:

- `cluster_endpoint`: Endpoint do cluster EKS
- `cluster_certificate_authority_data`: Certificado para conectar no cluster
- `ecr_repository_url`: URL do repositório ECR
- `vpc_id`: ID da VPC criada
- `private_subnets`: IDs das subnets privadas
- `public_subnets`: IDs das subnets públicas

## Nota sobre Deploy Kubernetes

Este projeto provisiona apenas a **infraestrutura AWS**. O deploy da aplicação no Kubernetes (ConfigMaps, Deployments, Services, etc.) deve ser feito em outro projeto que use os outputs deste projeto como input.