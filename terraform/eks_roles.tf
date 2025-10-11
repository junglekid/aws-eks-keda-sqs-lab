# Create IRSA Role for AWS ALB Service Account
module "load_balancer_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    alb = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# Create IRSA Role for Cluster Autoscaler
module "cluster_autoscaler_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  associations = {
    cluster-autoscaler = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "cluster-autoscaler-aws-cluster-autoscaler"
    }
  }
}

# Create IRSA Role for External DNS
module "external_dns_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [local.route53_zone_arn]

  associations = {
    external-dns = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "external-dns"
    }
  }
}

# Create IRSA Role for SQS
module "sqs_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-sqs"

  attach_custom_policy = true
  source_policy_documents = [
    data.aws_iam_policy_document.sqs_access.json
  ]

  # additional_policy_arns = {
  #   sqs_access = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.sqs_name}-policy"
  # }

  associations = {
    sqs = {
      cluster_name    = module.eks.cluster_name
      namespace       = "sqs-app"
      service_account = local.eks_sqs_app_service_account_name
    }
  }
}

# Create IRSA Role for SQS Keda
module "sqs_keda_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-sqs-keda"

  attach_custom_policy = true
  source_policy_documents = [
    data.aws_iam_policy_document.sqs_keda_access.json
  ]

  # additional_policy_arns = {
  #   sqs_keda_access = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.sqs_name}-keda-policy"
  # }

  associations = {
    sqs = {
      cluster_name    = module.eks.cluster_name
      namespace       = "keda"
      service_account = "keda-operator"
    }
  }
}
