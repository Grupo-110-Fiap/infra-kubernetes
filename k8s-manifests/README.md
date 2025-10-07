# Deploy da Aplicação no Kubernetes

Este diretório contém os manifestos YAML para fazer o deploy da aplicação no cluster EKS criado pelo Terraform.

## Pré-requisitos

1. Cluster EKS criado via Terraform
2. kubectl configurado para acessar o cluster
3. Imagem Docker disponível no ECR

## Como fazer o deploy

### 1. Configurar kubectl para o cluster EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name techchallenge-eks
```

### 2. Obter a URL do ECR Repository

Execute o terraform output no projeto de infraestrutura para obter a URL do ECR:

```bash
cd /path/to/infra-kubernetes
terraform output ecr_repository_url
```

### 3. Atualizar o arquivo deployment.yaml

Substitua `<ECR_REPOSITORY_URL>:<IMAGE_TAG>` no arquivo `deployment.yaml` pela URL real do ECR e tag da imagem.

### 4. Configurar o Secret com a URL do banco

Obtenha o endpoint do RDS do projeto infra-db:

```bash
cd /path/to/infra-db  
terraform output rds_endpoint
```

Codifique a URL de conexão do banco em base64:

```bash
echo -n "postgresql://fiap_arch:fiap_arch@<RDS_ENDPOINT>/<DB_NAME>" | base64
```

Atualize o arquivo `secret.yaml` com o valor codificado.

### 5. Aplicar os manifestos

```bash
kubectl apply -f k8s-manifests/
```

### 6. Verificar o deployment

```bash
# Verificar pods
kubectl get pods -n pedidos

# Verificar service
kubectl get svc -n pedidos

# Obter URL do Load Balancer
kubectl get svc pedidos-api -n pedidos -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Separação de Responsabilidades

- **Terraform**: Responsável apenas pela infraestrutura (EKS, VPC, ECR, etc.)
- **Kubernetes Manifests**: Responsável pelo deploy das aplicações
- **CI/CD**: Pode automatizar o deploy usando estes manifestos

Esta separação permite:
- Maior flexibilidade no deploy de aplicações
- Ciclos de desenvolvimento independentes da infraestrutura  
- Melhor controle de versioning das aplicações
- Possibilidade de usar ferramentas como Helm, Kustomize, etc.