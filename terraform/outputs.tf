# Output AWS Region
output "aws_region" {
  value = local.aws_region
}

# Output EKS Cluster Name
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_node_group_iam_role_name" {
  value = module.eks.eks_managed_node_groups["node_workers"].iam_role_name
}

# Output ECR Repo
output "ecr_sqs_consumer_repo_url" {
  value = module.ecr_sqs_consumer.repository_url
}

output "ecr_sqs_producer_repo_url" {
  value = module.ecr_sqs_producer.repository_url
}

# Output Domain Filter for External DNS
output "domain_filter" {
  value = local.public_base_domain_name
}

# Output Karpenter Interruption Queue
output "karpenter_interruption_queue" {
  value = module.karpenter.queue_name
}

# Output SQS App Information
output "sqs_app_domain_name" {
  value = "sqs-app.${local.public_base_domain_name}"
}

# Output EKS Service Account for SQS
output "sa_sqs_app_name" {
  value = local.eks_sqs_app_service_account_name
}

output "sqs_app_acm_certificate_arn" {
  value = aws_acm_certificate_validation.sqs_app.certificate_arn
}

output "sqs_queue_name" {
  value = module.sqs.queue_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}
