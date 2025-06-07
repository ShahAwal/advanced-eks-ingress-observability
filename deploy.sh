#!/bin/bash

# Exit on error
set -e

echo "=== Deploying Nginx Ingress Controller with AMP/AMG Integration ==="

# Step 1: Deploy infrastructure with Terraform
echo "Step 1: Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Step 2: Get outputs from Terraform
echo "Step 2: Getting Terraform outputs..."
AMP_ENDPOINT=$(cd terraform && terraform output -raw amp_endpoint)
AMP_INGEST_ROLE_ARN=$(cd terraform && terraform output -raw prometheus_ingest_role_arn)
AWS_REGION=$(cd terraform && terraform output -raw region)
GRAFANA_URL=$(cd terraform && terraform output -raw grafana_workspace_url)

# Step 3: Update kubeconfig
echo "Step 3: Updating kubeconfig..."
KUBECONFIG_CMD=$(cd terraform && terraform output -raw kubeconfig_command)
eval $KUBECONFIG_CMD

# Step 4: Install Nginx Ingress Controller
echo "Step 4: Installing Nginx Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -f values.yaml

# Step 5: Install test application with monitoring
echo "Step 5: Installing test application with monitoring..."
helm install modern-web ./charts/modern-web \
  --set prometheus.ampEndpoint=$AMP_ENDPOINT \
  --set prometheus.ampIngestRoleArn=$AMP_INGEST_ROLE_ARN \
  --set prometheus.awsRegion=$AWS_REGION

echo "=== Deployment Complete ==="
echo "Nginx Ingress Controller is now running"
echo "Prometheus is sending metrics to AMP at: $AMP_ENDPOINT"
echo "Grafana workspace URL: $GRAFANA_URL"
echo ""
echo "To access your application, check the ingress resources:"
echo "kubectl get ingress -A"