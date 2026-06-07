################################################################################
# Local Metadata Definitions
################################################################################
locals {
  name            = "eks-portfolio-cluster"
  region          = "us-east-1"
  cluster_version = "1.30"
  vpc_cidr        = "10.0.0.0/16"

  tags = {
    Environment = "dev"
    Project     = "EKS-GitOps"
  }
}

# Fetch availability zones dynamically within the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Networking Layer (VPC)
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  # Slice the first 3 active availability zones
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Keeps architecture cost-friendly for dev testing

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = local.tags
}

################################################################################
# Compute Layer (Amazon EKS)
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Standard internal cluster tools
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  # Cost-optimized compute node configurations
  eks_managed_node_groups = {
    general = {
      name           = "worker-nodes-dev"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      capacity_type = "ON_DEMAND"
    }
  }

  tags = local.tags
}