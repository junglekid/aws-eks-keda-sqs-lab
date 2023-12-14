# ### SQS
# resource "kubernetes_namespace" "sqs_app" {
#   metadata {
#     annotations = {
#       name = "sqs-app"
#     }

#     name = "sqs-app"
#   }

#   depends_on = [
#     module.eks,
#     aws_eks_node_group.eks
#   ]
# }

# resource "kubernetes_service_account" "sqs_service_account" {
#   metadata {
#     name      = local.eks_sqs_service_account_name
#     namespace = kubernetes_namespace.sqs_app.metadata[0].name
#     labels = {
#       "app.kubernetes.io/name" = local.eks_sqs_service_account_name
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn" = module.sqs_irsa_role.iam_role_arn
#     }
#   }

#   depends_on = [
#     module.eks,
#     aws_eks_node_group.eks
#   ]
# }

# ### Keda
# resource "kubernetes_namespace" "keda" {
#   metadata {
#     annotations = {
#       name = "keda"
#     }

#     name = "keda"
#   }

#   depends_on = [
#     module.eks,
#     aws_eks_node_group.eks
#   ]
# }
