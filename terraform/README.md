## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.16.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler_eks_pod_identity"></a> [cluster\_autoscaler\_eks\_pod\_identity](#module\_cluster\_autoscaler\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |
| <a name="module_ecr_sqs_consumer"></a> [ecr\_sqs\_consumer](#module\_ecr\_sqs\_consumer) | terraform-aws-modules/ecr/aws | ~> 3.1.0 |
| <a name="module_ecr_sqs_producer"></a> [ecr\_sqs\_producer](#module\_ecr\_sqs\_producer) | terraform-aws-modules/ecr/aws | ~> 3.1.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 21.3 |
| <a name="module_external_dns_eks_pod_identity"></a> [external\_dns\_eks\_pod\_identity](#module\_external\_dns\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 21.3 |
| <a name="module_load_balancer_eks_pod_identity"></a> [load\_balancer\_eks\_pod\_identity](#module\_load\_balancer\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |
| <a name="module_sqs"></a> [sqs](#module\_sqs) | terraform-aws-modules/sqs/aws | ~> 5.0 |
| <a name="module_sqs_eks_pod_identity"></a> [sqs\_eks\_pod\_identity](#module\_sqs\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |
| <a name="module_sqs_keda_eks_pod_identity"></a> [sqs\_keda\_eks\_pod\_identity](#module\_sqs\_keda\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 6.0 |
| <a name="module_vpc_cni_ipv4_eks_pod_identity"></a> [vpc\_cni\_ipv4\_eks\_pod\_identity](#module\_vpc\_cni\_ipv4\_eks\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.sqs_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.sqs_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.sqs_app_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sqs_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_keda_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.public_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [http_http.my_public_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | Output AWS Region |
| <a name="output_domain_filter"></a> [domain\_filter](#output\_domain\_filter) | Output Domain Filter for External DNS |
| <a name="output_ecr_sqs_consumer_repo_url"></a> [ecr\_sqs\_consumer\_repo\_url](#output\_ecr\_sqs\_consumer\_repo\_url) | Output ECR Repo |
| <a name="output_ecr_sqs_producer_repo_url"></a> [ecr\_sqs\_producer\_repo\_url](#output\_ecr\_sqs\_producer\_repo\_url) | n/a |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | n/a |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Output EKS Cluster Name |
| <a name="output_eks_node_group_iam_role_name"></a> [eks\_node\_group\_iam\_role\_name](#output\_eks\_node\_group\_iam\_role\_name) | n/a |
| <a name="output_karpenter_interruption_queue"></a> [karpenter\_interruption\_queue](#output\_karpenter\_interruption\_queue) | Output Karpenter Interruption Queue |
| <a name="output_sa_sqs_app_name"></a> [sa\_sqs\_app\_name](#output\_sa\_sqs\_app\_name) | Output EKS Service Account for SQS |
| <a name="output_sqs_app_acm_certificate_arn"></a> [sqs\_app\_acm\_certificate\_arn](#output\_sqs\_app\_acm\_certificate\_arn) | n/a |
| <a name="output_sqs_app_domain_name"></a> [sqs\_app\_domain\_name](#output\_sqs\_app\_domain\_name) | Output SQS App Information |
| <a name="output_sqs_queue_name"></a> [sqs\_queue\_name](#output\_sqs\_queue\_name) | n/a |
| <a name="output_sqs_queue_url"></a> [sqs\_queue\_url](#output\_sqs\_queue\_url) | n/a |
