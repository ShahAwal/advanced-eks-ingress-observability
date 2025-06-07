# EKS Cluster for Nginx Ingress Controller

This Terraform configuration creates an EKS cluster on AWS to deploy the Nginx Ingress Controller.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.12.1)
- kubectl installed

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. Configure kubectl to use the new cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name nginx-ingress-eks
```

5. Verify the cluster is working:
```bash
kubectl get nodes
```

## Deploy Nginx Ingress Controller

After the cluster is created, follow these steps to deploy the Nginx Ingress Controller:

```bash
# Create the namespace
kubectl create namespace ingress-nginx

# Apply the manifests
kubectl apply -f ../nginx-ingress-controller/manifests/

# Deploy the test application
kubectl create namespace dev
kubectl apply -f ../nginx-ingress-controller/test-app/
```