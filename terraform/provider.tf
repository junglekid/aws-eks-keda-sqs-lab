terraform {

  backend "s3" {
    bucket       = "dallin-tf-backend" # Update the bucket name
    key          = "eks-keda-sqs-lab"  # Update key name
    region       = "us-west-2"         # Update with aws region
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.10"
}

provider "aws" {
  region  = local.aws_region
  profile = local.aws_profile

  default_tags {
    tags = {
      Owner       = local.owner
      Environment = local.environment
      Project     = local.project
      Provisoner  = "Terraform"
    }
  }
}
