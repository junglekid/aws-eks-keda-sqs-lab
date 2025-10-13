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

output "eks_node_group_iam_role_arn" {
  value = module.eks.eks_managed_node_groups["node_workers"].iam_role_arn
}

# Output ECR Repo
output "ecr_sqs_consumer_repo_url" {
  value = module.ecr_sqs_consumer.repository_url
}

output "ecr_sqs_producer_repo_url" {
  value = module.ecr_sqs_producer.repository_url
}

# Output EKS Service Account for AWS Load Balancer Controller
# output "eks_sa_alb_iam_role_arn" {
#   value = module.load_balancer_controller_irsa_role.arn
# }

output "eks_sa_alb_eks_pod_identity_arn" {
  value = module.load_balancer_eks_pod_identity.iam_role_arn
}

# Output EKS Service Account for Cluster AutoScaler
# output "eks_sa_cluster_autoscaler_iam_role_arn" {
#   value = module.cluster_autoscaler_irsa_role.arn
# }

output "eks_sa_cluster_autoscaler_eks_pod_identity_arn" {
  value = module.cluster_autoscaler_eks_pod_identity.iam_role_arn
}

# Output EKS Service Account for External DNS
# output "eks_sa_external_dns_iam_role_arn" {
#   value = module.external_dns_irsa_role.arn
# }

output "eks_sa_external_dns_eks_pod_identity_arn" {
  value = module.external_dns_eks_pod_identity.iam_role_arn
}

# Output EKS Service Account for SQS App
# output "eks_sa_sqs_app_iam_role_arn" {
#   value = module.sqs_irsa_role.arn
# }

output "eks_sa_sqs_app_eks_pod_identity_arn" {
  value = module.sqs_eks_pod_identity.iam_role_arn
}

# Output EKS Service Account for SQS Keda
# output "eks_sa_sqs_keda_iam_role_arn" {
#   value = module.sqs_keda_irsa_role.arn
# }

output "eks_sa_sqs_keda_eks_pod_identity_arn" {
  value = module.sqs_keda_eks_pod_identity.iam_role_arn
}

# Output Domain Filter for External DNS
output "domain_filter" {
  value = local.public_base_domain_name
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

# output "sqs_queue_arn" {
#   value = module.sqs.queue_arn
# }

output "sqs_queue_name" {
  value = module.sqs.queue_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "interruption_queue" {
  value = module.karpenter.queue_name
}
