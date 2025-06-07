provider "aws" {
  region = var.region
}

# Create KMS key for EKS encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-encryption-key"
    }
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
  
  tags = var.tags
}

# Security group for EKS control plane to worker nodes communication
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # Enhanced security settings
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Enable secrets encryption using KMS
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]
  
  # Enable control plane logging
  cluster_enabled_log_types = var.cluster_enabled_log_types
  
  # Add cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  eks_managed_node_groups = {
    # System node group for cluster-critical addons
    system = {
      name           = var.system_node_group_config.name
      min_size       = var.system_node_group_config.min_size
      max_size       = var.system_node_group_config.max_size
      desired_size   = var.system_node_group_config.desired_size
      instance_types = var.system_node_group_config.instance_types
      
      capacity_type  = var.system_node_group_config.capacity_type
      
      # Enhanced security and monitoring
      enable_monitoring = true
      
      # Use custom launch template
      create_launch_template = true
      launch_template_name   = "${var.cluster_name}-system-node-group"
      
      # Root volume encryption and sizing
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.system_node_group_config.disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      
      # Add labels and taints for system workloads
      k8s_labels = var.system_node_group_config.labels
      
      taints = var.system_node_group_config.taints
      
      update_config = {
        max_unavailable_percentage = 25
      }
    }
    
    # Application node group for general workloads
    application = {
      name           = var.application_node_group_config.name
      min_size       = var.application_node_group_config.min_size
      max_size       = var.application_node_group_config.max_size
      desired_size   = var.application_node_group_config.desired_size
      instance_types = var.application_node_group_config.instance_types
      
      capacity_type  = var.application_node_group_config.capacity_type
      
      # Enhanced security and monitoring
      enable_monitoring = true
      
      # Use custom launch template
      create_launch_template = true
      launch_template_name   = "${var.cluster_name}-app-node-group"
      
      # Root volume encryption and sizing
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.application_node_group_config.disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      
      # Add labels for application workloads
      k8s_labels = var.application_node_group_config.labels
      
      taints = var.application_node_group_config.taints
      
      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }
  
  # AWS auth configuration for additional IAM roles/users
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  
  tags = var.tags
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}