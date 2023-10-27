#!/usr/bin/env bash

function replace_in_file() {
    if [ "$(uname)" == "Darwin" ]; then
        # Do something under Mac OS X platform
        sed -i '' -e "$1" "$2"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        sed -i -e "$1" "$2"
    fi
}

echo "Gathering AWS Resources and Names necessary to run the Kubernetes Applications and Services deployed by Flux from Terraform Output..."
echo "Hang on..."
echo "This can take between 30 to 90 seconds..."

# Set this to GitHub Repo hosting the SQS_APP Helm Chart
    SQS_APP_GITHUB_URL="https://github.com/junglekid/aws-eks-keda-sqs-lab"

cd ../terraform
AWS_REGION=$(terraform output -raw aws_region)
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
ECR_SQS_CONSUMER_REPO=$(terraform output -raw ecr_sqs_consumer_repo_url)
ECR_SQS_PRODUCER_REPO=$(terraform output -raw ecr_sqs_producer_repo_url)
EXTERNAL_DNS_DOMAIN_FILTER=$(terraform output -raw domain_filter)
SA_ALB_IAM_ROLE_ARN=$(terraform output -raw eks_sa_alb_iam_role_arn)
SA_CLUSTER_AUTOSCALER_IAM_ROLE_ARN=$(terraform output -raw eks_sa_cluster_autoscaler_iam_role_arn)
SA_EXTERNAL_DNS_IAM_ROLE_ARN=$(terraform output -raw eks_sa_external_dns_iam_role_arn)
SA_SQS_KEDA_IAM_ROLE_ARN=$(terraform output -raw eks_sa_sqs_keda_iam_role_arn)
SA_SQS_APP_NAME=$(terraform output -raw sa_sqs_app_name)
SQS_APP_DOMAIN_NAME=$(terraform output -raw sqs_app_domain_name)
AWS_ACM_SQS_APP_ARN=$(terraform output -raw sqs_app_acm_certificate_arn)
SQS_QUEUE_NAME=$(terraform output -raw sqs_queue_name)
SQS_QUEUE_URL=$(terraform output -raw sqs_queue_url)

echo ""
echo "Configuring Apps managed by FluxCD..."
echo ""

cd ..
# Configure SQS Consumer App
cp -f ./k8s/templates/apps/base/sqs-consumer/config.yaml ./k8s/apps/base/sqs-consumer/config.yaml
replace_in_file 's|AWS_REGION|'"$AWS_REGION"'|g' ./k8s/apps/base/sqs-consumer/config.yaml
replace_in_file 's|SQS_QUEUE_URL|'"$SQS_QUEUE_URL"'|g' ./k8s/apps/base/sqs-consumer/config.yaml

cp -f ./k8s/templates/apps/base/sqs-consumer/release.yaml ./k8s/apps/base/sqs-consumer/release.yaml
replace_in_file 's|ECR_SQS_CONSUMER_REPO|'"$ECR_SQS_CONSUMER_REPO"'|g' ./k8s/apps/base/sqs-consumer/release.yaml
replace_in_file 's|SA_SQS_APP_NAME|'"$SA_SQS_APP_NAME"'|g' ./k8s/apps/base/sqs-consumer/release.yaml
replace_in_file 's|SQS_QUEUE_NAME|'"$SQS_QUEUE_NAME"'|g' ./k8s/apps/base/sqs-consumer/release.yaml

# Configure SQS Producer App
cp -f ./k8s/templates/apps/base/sqs-producer/release.yaml ./k8s/apps/base/sqs-producer/release.yaml
replace_in_file 's|AWS_ACM_SQS_APP_ARN|'"$AWS_ACM_SQS_APP_ARN"'|g' ./k8s/apps/base/sqs-producer/release.yaml
replace_in_file 's|ECR_SQS_PRODUCER_REPO|'"$ECR_SQS_PRODUCER_REPO"'|g' ./k8s/apps/base/sqs-producer/release.yaml
replace_in_file 's|SA_SQS_APP_NAME|'"$SA_SQS_APP_NAME"'|g' ./k8s/apps/base/sqs-producer/release.yaml
replace_in_file 's|SQS_APP_DOMAIN_NAME|'"$SQS_APP_DOMAIN_NAME"'|g' ./k8s/apps/base/sqs-producer/release.yaml
replace_in_file 's|SQS_QUEUE_NAME|'"$SQS_QUEUE_NAME"'|g' ./k8s/apps/base/sqs-producer/release.yaml

# Configure Source for SQS Consumer and SQS Producer Apps
cp -f ./k8s/templates/apps/sources/sqs-app.yaml ./k8s/apps/sources/sqs-app.yaml
replace_in_file 's|SQS_APP_GITHUB_URL|'"$SQS_APP_GITHUB_URL"'|g' ./k8s/apps/sources/sqs-app.yaml

# Configure AWS Load Balanancer Controller
cp -f ./k8s/templates/infrastructure/controllers/aws-load-balancer-controller/release.yaml ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml
replace_in_file 's|AWS_REGION|'"$AWS_REGION"'|g' ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml
replace_in_file 's|EKS_CLUSTER_NAME|'"$EKS_CLUSTER_NAME"'|g' ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml
replace_in_file 's|SA_ALB_IAM_ROLE_ARN|'"$SA_ALB_IAM_ROLE_ARN"'|g' ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml

# Configure Cluster Autoscaler
cp -f ./k8s/templates/infrastructure/controllers/cluster-autoscaler/release.yaml ./k8s/infrastructure/controllers/cluster-autoscaler/release.yaml
replace_in_file 's|AWS_REGION|'"$AWS_REGION"'|g' ./k8s/infrastructure/controllers/cluster-autoscaler/release.yaml
replace_in_file 's|EKS_CLUSTER_NAME|'"$EKS_CLUSTER_NAME"'|g' ./k8s/infrastructure/controllers/cluster-autoscaler/release.yaml
replace_in_file 's|SA_CLUSTER_AUTOSCALER_IAM_ROLE_ARN|'"$SA_CLUSTER_AUTOSCALER_IAM_ROLE_ARN"'|g' ./k8s/infrastructure/controllers/cluster-autoscaler/release.yaml

# Configure External DNS
cp -f ./k8s/templates/infrastructure/controllers/external-dns/release.yaml ./k8s/infrastructure/controllers/external-dns/release.yaml
replace_in_file 's|AWS_REGION|'"$AWS_REGION"'|g' ./k8s/infrastructure/controllers/external-dns/release.yaml
replace_in_file 's|EKS_CLUSTER_NAME|'"$EKS_CLUSTER_NAME"'|g' ./k8s/infrastructure/controllers/external-dns/release.yaml
replace_in_file 's|EXTERNAL_DNS_DOMAIN_FILTER|'"$EXTERNAL_DNS_DOMAIN_FILTER"'|g' ./k8s/infrastructure/controllers/external-dns/release.yaml
replace_in_file 's|SA_EXTERNAL_DNS_IAM_ROLE_ARN|'"$SA_EXTERNAL_DNS_IAM_ROLE_ARN"'|g' ./k8s/infrastructure/controllers/external-dns/release.yaml

# Configure Keda
cp -f ./k8s/templates/infrastructure/controllers/keda/release.yaml ./k8s/infrastructure/controllers/keda/release.yaml
replace_in_file 's|SA_SQS_KEDA_IAM_ROLE_ARN|'"$SA_SQS_KEDA_IAM_ROLE_ARN"'|g' ./k8s/infrastructure/controllers/keda/release.yaml

echo ""
echo "Pushing changes to Git repository..."
echo ""

# Add SQS App files
git add ./k8s/apps/base/sqs-consumer/config.yaml
git add ./k8s/apps/base/sqs-consumer/release.yaml
git add ./k8s/apps/base/sqs-producer/release.yaml

git add ./k8s/apps/sources/sqs-app.yaml

# Add Infrastructure Controller files
git add ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml
git add ./k8s/infrastructure/controllers/external-dns/release.yaml
git add ./k8s/infrastructure/controllers/cluster-autoscaler/release.yaml
git add ./k8s/infrastructure/controllers/keda/release.yaml

git commit -m "Updating Apps"
git push &> /dev/null

echo ""
echo "Finished configuring Apps managed by FluxCD..."
