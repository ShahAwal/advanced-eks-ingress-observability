# Nginx Ingress Controller for Kubernetes - Helm Deployment with Observability

A production-ready implementation of the Nginx Ingress Controller for Kubernetes using Helm, integrated with AWS Managed Prometheus (AMP) and AWS Managed Grafana (AMG) for observability.

## Project Structure

```
├── charts/
│   └── modern-web/     # Modern web application Helm chart with integrated monitoring
├── terraform/          # Infrastructure as code including AMP and AMG
├── values.yaml         # Helm values for Nginx Ingress Controller
└── deploy.sh           # Unified deployment script
```

## Deployment Instructions

### One-Step Deployment

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

This script will:
1. Deploy infrastructure with Terraform (EKS, AMP, AMG)
2. Configure kubectl to connect to the EKS cluster
3. Install Nginx Ingress Controller using Helm
4. Deploy the test application with integrated monitoring

### Manual Deployment Steps

If you prefer to deploy components individually:

#### 1. Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

#### 2. Install Nginx Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -f values.yaml
```

#### 3. Deploy Test Application with Monitoring

```bash
# Get AMP endpoint and role ARN from Terraform outputs
AMP_ENDPOINT=$(cd terraform && terraform output -raw amp_endpoint)
AMP_INGEST_ROLE_ARN=$(cd terraform && terraform output -raw prometheus_ingest_role_arn)
AWS_REGION=$(cd terraform && terraform output -raw region)

# Install application with monitoring
helm install modern-web ./charts/modern-web \
  --set prometheus.ampEndpoint=$AMP_ENDPOINT \
  --set prometheus.ampIngestRoleArn=$AMP_INGEST_ROLE_ARN \
  --set prometheus.awsRegion=$AWS_REGION
```

## Observability Features

### Amazon Managed Prometheus (AMP)
- Fully managed Prometheus-compatible monitoring service
- Automatic scaling and high availability
- Long-term metrics storage
- Integrated with AWS security services

### Amazon Managed Grafana (AMG)
- Fully managed Grafana service for data visualization
- Pre-configured dashboards for Nginx Ingress Controller
- Integration with AWS IAM for authentication
- Alerting capabilities

### Metrics Collected
- Request rate by status code
- Latency percentiles (p50, p95, p99)
- Error rates
- Connection metrics
- Resource utilization

## Security Features

The Nginx Ingress Controller deployment includes the following security enhancements:

- Strict TLS configuration with modern ciphers
- Comprehensive security headers
- Network policies for traffic isolation
- Pod security context with least privilege
- Resource limits to prevent DoS
- Readiness and liveness probes for reliability
- Metrics collection for monitoring

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.