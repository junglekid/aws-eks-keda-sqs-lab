# Create AWS EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.3"

  name                                     = local.eks_cluster_name
  kubernetes_version                       = "1.34"
  endpoint_private_access                  = true
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  addons = {
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.vpc_cni_ipv4_eks_pod_identity.iam_role_arn
      before_compute              = true
    }
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      before_compute              = true
    }
  }

  eks_managed_node_groups = {
    node_workers = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["m6a.large", "m6i.large"]
      capacity_type  = "SPOT"
      subnet_ids     = module.vpc.private_subnets

      min_size     = 3
      max_size     = 20
      desired_size = 3

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # IMDSv2 only
        http_put_response_hop_limit = 2          # REQUIRED for Pod Identity!
        instance_metadata_tags      = "enabled"
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "vpc_cni_ipv4_eks_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.eks_iam_role_prefix}-vpc-cni-ipv4"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  # Pod Identity Associations
  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-node"
  }

  associations = {
    vpc_cni = {
      cluster_name = module.eks.cluster_name
    }
  }
}
