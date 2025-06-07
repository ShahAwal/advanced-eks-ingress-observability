variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "nginx-ingress-eks"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Should be true if you want to create a VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "system_node_group_config" {
  description = "Configuration for the system node group"
  type        = any
  default     = {
    name           = "system-node-group"
    min_size       = 2
    max_size       = 3
    desired_size   = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    labels = {
      "node.kubernetes.io/purpose" = "system"
    }
    taints = [
      {
        key    = "dedicated"
        value  = "system"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

variable "application_node_group_config" {
  description = "Configuration for the application node group"
  type        = any
  default     = {
    name           = "app-node-group"
    min_size       = 2
    max_size       = 10
    desired_size   = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100
    labels = {
      "node.kubernetes.io/purpose" = "application"
    }
    taints = []
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "production"
    Terraform   = "true"
    Project     = "nginx-ingress"
  }
}

variable "create_grafana" {
  description = "Whether to create Grafana workspace"
  type        = bool
  default     = false
}
