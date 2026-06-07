provider "aws" {
  region = "us-east-1"
}

# 1. Create the S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "lakshmi-eks-gitops-state-bucket" # Must be globally unique
  force_destroy = true                              # Prevents accidental deletion of your state files

  tags = {
    Name        = "Terraform State Backend"
    Environment = "Dev"
  }
}

# Enable Versioning so you can recover older versions of your state if something gets corrupted
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. Create the DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "lakshmi-terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST" # Cost-efficient for portfolio/dev projects
  hash_key     = "LockID"          # This attribute name is strictly required by Terraform

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Dev"
  }
}