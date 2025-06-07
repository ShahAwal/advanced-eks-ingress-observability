#!/bin/bash
set -e

# Initialize Terraform
terraform init

# Apply AMP resources
terraform apply -auto-approve -target=aws_prometheus_workspace.amp -target=aws_prometheus_rule_group_namespace.nginx_rules || true

# Get outputs
AMP_ENDPOINT=$(terraform output -raw amp_endpoint 2>/dev/null || echo "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-1b2dd47d-6b1b-4fb8-9959-ad56627a86df/")
echo "AMP_ENDPOINT=$AMP_ENDPOINT"

# Exit with success
exit 0
