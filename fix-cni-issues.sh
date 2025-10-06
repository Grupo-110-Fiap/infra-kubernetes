#!/bin/bash

echo "🔧 Fixing EKS CNI Issues..."

# 1. Apply Terraform changes to add EKS add-ons and improve networking
echo "📝 Applying Terraform configuration updates..."
terraform plan -out=tfplan
terraform apply tfplan

# 2. Wait for add-ons to be ready
echo "⏳ Waiting for EKS add-ons to be ready..."
kubectl rollout status daemonset/aws-node -n kube-system --timeout=300s
kubectl rollout status deployment/coredns -n kube-system --timeout=300s

# 3. Restart any problematic pods
echo "🔄 Restarting pedidos deployment..."
kubectl rollout restart deployment/pedidos-api -n pedidos

# 4. Verify cluster health
echo "🔍 Checking cluster health..."
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n pedidos

# 5. Check for any remaining CNI issues
echo "🕵️ Checking for CNI issues..."
kubectl get events --all-namespaces --field-selector type=Warning | grep -i cni || echo "✅ No CNI warnings found"

echo "✨ CNI issue fix complete!"
echo ""
echo "💡 If you still see CNI issues:"
echo "   1. Check subnet IP availability: kubectl describe nodes"
echo "   2. Restart AWS CNI: kubectl rollout restart daemonset/aws-node -n kube-system"
echo "   3. Check AWS CNI logs: kubectl logs -n kube-system -l k8s-app=aws-node"