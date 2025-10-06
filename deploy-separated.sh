#!/bin/bash

echo "🚀 Deploying EKS Infrastructure and Applications..."

# Step 1: Deploy infrastructure only (without Kubernetes resources)
echo "📦 Step 1: Deploying EKS infrastructure..."
cp main.tf main-original.tf
cp main-infra-only.tf main.tf

terraform plan -var="terraform_state_bucket=terraform-kajgfkafvbajbfkagfskahgdfiahfkds" -out=infra-plan
if [ $? -eq 0 ]; then
    terraform apply infra-plan
    echo "✅ Infrastructure deployment completed!"
else
    echo "❌ Infrastructure planning failed!"
    exit 1
fi

# Step 2: Update kubectl context
echo "🔧 Step 2: Updating kubectl context..."
aws eks update-kubeconfig --region us-east-1 --name techchallenge-eks

# Step 3: Wait for EKS addons to be ready
echo "⏳ Step 3: Waiting for EKS addons to be ready..."
kubectl rollout status daemonset/aws-node -n kube-system --timeout=300s
kubectl rollout status deployment/coredns -n kube-system --timeout=300s

# Step 4: Deploy Kubernetes resources manually
echo "🚀 Step 4: Deploying application resources..."

# Create namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: pedidos
EOF

# Create configmap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: pedidos-config
  namespace: pedidos
data:
  DB_TYPE: "postgres"
  APP_ENV: "dev"
  GIN_MODE: "release"
EOF

# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_hostname)
RDS_DB_NAME=$(terraform output -raw rds_db_name)

# Create secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: pedidos-secret
  namespace: pedidos
type: Opaque
data:
  DATABASE_URL: $(echo "postgresql://fiap_arch:fiap_arch@${RDS_ENDPOINT}/${RDS_DB_NAME}" | base64 -w 0)
EOF

# Get ECR URI
ECR_URI=$(terraform output -raw ecr_repository_url)

# Create deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pedidos-api
  namespace: pedidos
  labels:
    app: pedidos-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pedidos-api
  template:
    metadata:
      labels:
        app: pedidos-api
    spec:
      containers:
      - name: pedidos-api
        image: ${ECR_URI}:latest
        ports:
        - containerPort: 8081
        envFrom:
        - configMapRef:
            name: pedidos-config
        - secretRef:
            name: pedidos-secret
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
EOF

# Create service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: pedidos-api
  namespace: pedidos
spec:
  selector:
    app: pedidos-api
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8081
    protocol: TCP
EOF

echo "✨ Deployment completed!"
echo ""
echo "📊 Checking deployment status..."
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n pedidos
kubectl get svc -n pedidos

echo ""
echo "🔍 To check for any remaining issues:"
echo "   kubectl get events --all-namespaces --sort-by='.lastTimestamp'"
echo "   kubectl logs -n pedidos -l app=pedidos-api"