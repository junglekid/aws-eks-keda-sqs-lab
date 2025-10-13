locals {
  # AWS Provider
  aws_region  = "us-west-2"  # Update with aws region
  aws_profile = "bsisandbox" # Update with aws profile

  # Account ID
  # account_id = data.aws_caller_identity.current.account_id

  # Tags
  owner       = "Dallin Rasmuson" # Update with owner name
  environment = "Sandbox"
  project     = "AWS EKS Keda and SQS Lab"

  # VPC Configuration
  vpc_name = "eks-keda-sqs-lab-vpc"
  vpc_cidr = "10.226.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # ECR Configuration
  ecr_sqs_repo_name = "eks-keda-sqs-lab"

  # SQS Configuration
  sqs_name = "eks-keda-sqs-lab"

  # EKS Configuration
  eks_cluster_name                 = "eks-keda-sqs-lab"
  eks_cluster_version              = "1.34"
  eks_iam_role_prefix              = "eks-keda-sqs-lab"
  eks_sqs_app_service_account_name = "sa-aws-sqs-app"

  # ACM and Route53 Configuration
  public_base_domain_name = "dallin.brewsentry.com" # Update with your root domain
  route53_zone_id         = data.aws_route53_zone.public_domain.zone_id
  route53_zone_arn        = data.aws_route53_zone.public_domain.arn

  # Retrieve Public IP Address
  my_public_ip = chomp(data.http.my_public_ip.response_body)
}
