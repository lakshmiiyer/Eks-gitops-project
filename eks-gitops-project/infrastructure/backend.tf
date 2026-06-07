terraform {
  required_version = ">= 1.5.0"

  # 1. Secure Remote State Storage
  backend "s3" {
    bucket         = "lakshmi-eks-gitops-state-bucket"
    key            = "dev/eks-gitops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lakshmi-terraform-lock-table"
    encrypt        = true
  }

  # 2. Strict Provider Tracking
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}