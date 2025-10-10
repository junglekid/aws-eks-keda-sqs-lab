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
      # service_account_role_arn    = module.vpc_cni_ipv4_eks_pod_identity.iam_role_arn
      # before_compute              = true
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

      update_config = {
        max_unavailable = 1
      }
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# # Create AWS EKS Node Group
# resource "aws_eks_node_group" "eks" {
#   cluster_name    = module.eks.cluster_name
#   node_group_name = "node_workers"
#   node_role_arn   = aws_iam_role.eks_node.arn
#   subnet_ids      = module.vpc.private_subnets
#   instance_types  = ["m6a.large", "m6i.large"]
#   capacity_type   = "SPOT"

#   scaling_config {
#     desired_size = 3
#     max_size     = 20
#     min_size     = 3
#   }

#   update_config {
#     max_unavailable = 1
#   }
# }

# # Create AWS IAM Role for EKS Nodes
# resource "aws_iam_role" "eks_node" {
#   name = "${local.eks_iam_role_prefix}-node-group-role"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }

# # Attach AWS IAM Policy to IAM Role for EKS Nodes
# resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node.name
# }

# # Attach AWS IAM Policy to IAM Role for EKS Nodes
# resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_node.name
# }

# # Attach AWS IAM Policy to IAM Role for EKS Nodes
# resource "aws_iam_role_policy_attachment" "eks_node-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node.name
# }

# Create IAM Role for AWS VPC CNI Service Account
# module "vpc_cni_ipv4_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"

#   name                  = "${local.eks_iam_role_prefix}-vpc-cni-ipv4"
#   attach_vpc_cni_policy = true
#   vpc_cni_enable_ipv4   = true

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-node"]
#     }
#   }
# }

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
