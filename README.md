# Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)

![Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)](./images/aws_eks_keda_sqs.png)

[![Terraform](https://img.shields.io/badge/Terraform-%5E1.10-blue)](https://developer.hashicorp.com/terraform)
[![KEDA](https://img.shields.io/badge/KEDA-v2.x-green)](https://keda.sh/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![FluxCD](https://img.shields.io/badge/FluxCD-GitOps-lightblue)](https://fluxcd.io/)

## Table of Contents

1. [Introduction](#introduction)
2. [What is Kubernetes Event-driven Autoscaling (KEDA)?](#what-is-kubernetes-event-driven-autoscaling-keda)
   1. [Benefits of using KEDA with Amazon EKS](#benefits-of-using-keda-with-amazon-eks)
3. [Architecture Overview](#architecture-overview)
4. [Prerequisites](#prerequisites)
5. [Setup and Deploy Infrastructure](#setup-and-deploy-infrastructure)
6. [Configure access to Amazon EKS Cluster](#configure-access-to-amazon-eks-cluster)
7. [Create and Push SQS App Docker Images to Amazon ECR](#create-and-push-sqs-app-docker-images-to-amazon-ecr)
   1. [Build the Docker Images](#build-the-docker-images)
   2. [Push the Docker Images to Amazon ECR](#push-the-docker-images-to-amazon-ecr)
8. [Configure and Install Flux](#configure-and-install-flux)
9. [Managing Flux](#managing-flux)
10. [Kubernetes Addons managed by Flux](#kubernetes-addons-managed-by-flux)
11. [Applications managed by Flux](#applications-managed-by-flux)
12. [Demo](#demo)
13. [Clean Up](#clean-up)
    1. [Clean up Applications managed by Flux from Kubernetes](#clean-up-applications-managed-by-flux-from-kubernetes)
    2. [Clean up Kubernetes AddOns managed by Flux from Kubernetes](#clean-up-kubernetes-addons-managed-by-flux-from-kubernetes)
    3. [Uninstall Flux from Kubernetes](#uninstall-flux-from-kubernetes)
    4. [Clean up Terraform](#clean-up-terraform)
14. [Conclusion](#conclusion)

## Introduction

## Introduction

This guide demonstrates how to implement event-driven autoscaling for AWS SQS message processing using KEDA (Kubernetes Event-driven Autoscaling) on Amazon EKS. You'll learn how to automatically scale your Kubernetes workloads from zero to hundreds of pods based on the number of messages in an SQS queue, then scale back down to zero when the queue is empty.

**What You'll Build**: A complete infrastructure that processes messages from an AWS SQS queue using Kubernetes pods that automatically scale based on queue depth. When messages arrive, KEDA triggers pod creation. When the queue empties, pods scale down to zero, saving costs.

You can access the complete code in my [GitHub Repository](https://github.com/junglekid/aws-eks-keda-sqs-lab).

## What is Kubernetes Event-driven Autoscaling (KEDA)?

[KEDA](https://keda.sh/) is an application-level autoscaler for Kubernetes workloads. It extends the basic autoscaling capabilities provided by Kubernetes, allowing you to scale applications in response to real-time events rather than just metrics like CPU or memory usage. Here are the key features and concepts of KEDA:

### Key Features

**Event-Driven**: KEDA works by scaling applications based on events from various sources, such as message queues, databases, timers, or any event source that can provide metrics. This allows for more dynamic and responsive scaling compared to traditional metric-based autoscaling.

**Support for Multiple Event Sources**: KEDA supports a wide range of event sources, including popular message queues like Kafka, RabbitMQ, Azure Service Bus, AWS SQS, and many others. It can also integrate with custom event sources.

**Seamless Integration with Kubernetes**: KEDA is implemented as a Kubernetes Operator, which means it integrates seamlessly with the Kubernetes ecosystem. It extends Kubernetes by adding new custom resources that define how applications should scale in response to events.

**ScaledObject Custom Resource**: The key custom resource in KEDA is the `ScaledObject`. This resource defines how a particular deployment or job should scale in response to events. You specify the target event source, the scaling triggers, and other scaling parameters in a `ScaledObject`.

**Scale-to-Zero**: One of the unique features of KEDA is its ability to scale workloads down to zero pods. This means that when there are no events to process, the application can release all its resources, leading to cost savings, especially in cloud environments.

**Horizontal Pod Autoscaler (HPA) Integration**: KEDA can work in conjunction with Kubernetes' built-in Horizontal Pod Autoscaler. It activates the HPA based on event metrics, allowing for a more dynamic and responsive autoscaling mechanism.

**Flexible and Extensible**: KEDA is designed to be extensible, allowing for the addition of new scalers (event sources) as needed. Its architecture is modular, which makes it easier to extend and adapt to specific needs.

KEDA is particularly useful for applications that need to respond quickly to fluctuating workloads, such as those processing events from message queues or reacting to real-time data streams. Its ability to scale to zero also makes it an attractive option for cost optimization in cloud-native environments.

### Benefits of using KEDA with Amazon EKS

Using Kubernetes Event-driven Autoscaling (KEDA) with Amazon Elastic Kubernetes Service (EKS) offers several benefits, particularly for organizations looking to build and manage scalable, event-driven applications in a cloud environment. Here are some of the key advantages:

**Efficient Resource Utilization**: KEDA's ability to scale applications based on actual demand, including scaling to zero, ensures efficient use of resources. This is particularly beneficial in a cloud environment like EKS where resource usage directly impacts costs.

**Enhanced Scalability for Event-Driven Workloads**: EKS provides a robust platform for running Kubernetes workloads, and KEDA enhances this by enabling more responsive and dynamic scaling based on events. This is ideal for workloads that are event-driven, such as those processing messages from queues or reacting to changes in databases.

**Cost-Effective**: By scaling workloads to zero when not in use, KEDA helps to reduce costs. In an EKS environment, where you pay for the resources you use, this can lead to significant savings, especially for workloads with variable or sporadic traffic patterns.

**Seamless Integration**: KEDA integrates seamlessly with EKS, allowing for easy deployment and management of event-driven autoscaling. This integration simplifies the operational complexity and reduces the effort required to manage application scaling.

**Support for a Wide Range of Event Sources**: KEDA supports numerous event sources, including those commonly used in AWS environments, like Amazon SQS, SNS, and CloudWatch. This makes it versatile and suitable for various application scenarios in EKS.

**Improved Application Performance and Responsiveness**: By automatically scaling based on real-time events, applications can maintain optimal performance levels, responding efficiently to spikes in demand without manual intervention.

**Flexibility and Customization**: KEDA allows for detailed customization of scaling rules and triggers, giving teams the flexibility to tailor the scaling behavior to their specific application needs and traffic patterns.

**Simplified DevOps Processes**: With KEDA handling the complexity of event-driven autoscaling, DevOps teams can focus more on other aspects of application development and infrastructure management, improving overall operational efficiency.

**Better Use of EKS Features**: KEDA complements EKS's existing features, like network policies, security groups, and load balancing, ensuring that the autoscaling process is not just effective but also secure and well-integrated with the overall infrastructure.

**Community and Ecosystem Support**: Being an open-source project, KEDA benefits from strong community support and continuous development. This ensures compatibility with the latest Kubernetes features and trends, which is crucial for maintaining a modern cloud-native infrastructure on EKS.

In summary, integrating KEDA with EKS enhances the capabilities of Kubernetes in handling event-driven, dynamic workloads in a cloud environment, leading to improved performance, cost efficiency, and operational simplicity.

![KEDA Architecture](./images/keda_arch.png)

## Architecture Overview

This solution uses the following AWS and open-source technologies:

### Infrastructure Components

- **Amazon EKS**: Managed Kubernetes cluster hosting all workloads
- **Amazon VPC**: Isolated network environment with public and private subnets
- **AWS KMS**: Encryption keys for securing EKS secrets and ECR images
- **HashiCorp Terraform**: Infrastructure as Code for reproducible deployments

### Application Components

- **Amazon ECR**: Container registry for SQS consumer and producer images
- **Amazon SQS**: Message queue that triggers autoscaling events
- **KEDA**: Event-driven autoscaler monitoring SQS queue depth
- **Flux CD**: GitOps tool managing continuous deployment

### Kubernetes Addons

- **AWS Load Balancer Controller**: Provisions ALBs for ingress traffic
- **External DNS**: Automatically creates Route 53 DNS records
- **Karpenter**: Just-in-time node provisioning for optimal resource usage
- **Metrics Server**: Provides resource metrics for Kubernetes

### Security & Networking

- **IAM Roles and Policies**: Fine-grained permissions using IRSA
- **Amazon Route 53**: DNS management for application endpoints
- **AWS Certificate Manager**: SSL/TLS certificates for secure connections

## How This Demo Works

### Application Flow

1. **Message Production**: The SQS Producer application sends messages to an AWS SQS queue at a configurable rate
2. **KEDA Monitoring**: KEDA continuously polls the SQS queue to check the approximate number of messages
3. **Scaling Decision**: When messages exceed the threshold (default: 5 messages per pod), KEDA triggers scaling
4. **Pod Creation**: New consumer pods are created to process messages in parallel
5. **Message Processing**: Consumer pods retrieve messages from SQS, process them, and delete them from the queue
6. **Scale Down**: As the queue empties, KEDA gradually scales down the number of consumer pods
7. **Scale to Zero**: When the queue is empty for the cooldown period, all consumer pods are terminated

### KEDA ScaledObject Configuration

The demo uses a KEDA ScaledObject that defines:

- **Trigger**: AWS SQS queue with specific queue name and region
- **Queue Length Target**: Number of messages per pod (e.g., 5 messages per pod)
- **Min Replicas**: 0 (allows scale-to-zero)
- **Max Replicas**: Configurable upper limit (e.g., 30 pods)
- **Polling Interval**: How often KEDA checks the queue (e.g., every 30 seconds)
- **Cooldown Period**: Time to wait before scaling down (e.g., 300 seconds)

This configuration ensures efficient processing while preventing over-scaling and managing costs.

## Prerequisites

Before you begin, ensure you have the following tools and accounts configured:

### Required Accounts

1. **AWS Account**: Active AWS account with administrative access. [Create an account here](https://repost.aws/knowledge-center/create-and-activate-aws-account)
2. **GitHub Account**: For storing and managing your GitOps repository

### Required Tools

| Tool | Purpose | Installation Guide |
|------|---------|-------------------|
| AWS CLI | Interact with AWS services | [Installation Guide](https://aws.amazon.com/cli/) |
| Terraform | Infrastructure as Code deployment | [Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) |
| kubectl | Kubernetes command-line tool | [Installation Guide](https://kubernetes.io/docs/tasks/tools/#kubectl) |
| Helm | Kubernetes package manager | [Installation Guide](https://helm.sh/docs/intro/install) |
| Flux CLI | GitOps toolkit for Kubernetes | [Installation Guide](https://fluxcd.io/flux/installation/#install-the-flux-cli) |
| Docker | Build and manage container images | [Installation Guide](https://docs.docker.com/get-docker/) |
| k9s (Optional) | Terminal UI for Kubernetes / Kubernetes CLI To Manage Your Clusters In Style | [Installation Guide](https://k9scli.io/topics/install/) |

### GitHub Personal Access Token

Create a GitHub Personal Access Token with the following scopes:
- `repo` (full control of private repositories)
- `admin:repo_hook` (write repository hooks)

[Create your token here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

**Important**: Save your token securely - you'll need it during Flux installation.

### Verify Prerequisites

After installing all tools, verify they're working:

```bash
aws --version
terraform --version
kubectl version --client
helm version
flux --version
docker --version
```

## Setup and Deploy Infrastructure

### Step 1: Configure Terraform Variables

Navigate to the `terraform` directory and open `locals.tf`. Update the following variables:

```hcl
locals {
  # AWS Configuration
  aws_region  = "us-east-1"  # Your preferred AWS region
  aws_profile = "default"     # Your AWS CLI profile name

  # Domain Configuration
  # custom_domain_name: subdomain for your applications (e.g., "keda-demo")
  # public_base_domain_name: your Route 53 hosted zone (e.g., "example.com")
  # Result: Applications accessible at keda-demo.example.com
  custom_domain_name      = "keda-demo"
  public_base_domain_name = "example.com"

  # Resource Tagging
  tags = {
    Environment = "dev"
    Project     = "eks-keda-sqs-lab"
    ManagedBy   = "terraform"
    Owner       = "your-email@example.com"
  }
}
```

**Note**: Ensure the `public_base_domain_name` matches a Route 53 hosted zone in your AWS account.

### Step 2: Configure Terraform Backend

Open `provider.tf` and update the S3 backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"    # S3 bucket for state storage
    key            = "eks-keda-sqs/terraform.tfstate" # Update to Preferred Key Name
    region         = "us-west-2"                      # Update to Preferred AWS Region
    encrypt      = true
    use_lockfile = true
  }
}
```

**Prerequisites for backend**:

- Create the S3 bucket with versioning enabled

### Step 3: Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review planned changes
terraform plan -out=plan.out

# Apply the infrastructure
terraform apply plan.out
```

### Step 4: Verify Deployment

After successful deployment (approximately 15-20 minutes), you should see:

```bash
Apply complete! Resources: 50+ added, 0 changed, 0 destroyed.

Outputs:
aws_region = "us-east-1"
eks_cluster_name = "eks-keda-sqs-lab"
ecr_sqs_consumer_repo_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/sqs-consumer"
ecr_sqs_producer_repo_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/sqs-producer"
sqs_queue_name = "keda-demo-queue"
```

![Terraform Apply](./images/terraform_apply.png)

## Configure Access to Amazon EKS Cluster

Update your local kubeconfig to access the newly created EKS cluster:

```bash
# Navigate to terraform directory
cd terraform

# Extract cluster information from Terraform outputs
AWS_REGION=$(terraform output -raw aws_region)
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Update kubeconfig
aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
```

**Expected output**:
```
Added new context arn:aws:eks:us-east-1:123456789012:cluster/eks-keda-sqs-lab to /Users/username/.kube/config
```

![Configure Amazon EKS Cluster](./images/kubeconfig.png)

**Verify cluster access**:
```bash
kubectl get nodes
kubectl cluster-info
```

You should see your EKS nodes listed and cluster endpoints displayed.

## Create and Push SQS App Docker Images to Amazon ECR

### Step 1: Set Environment Variables

```bash
# Navigate to terraform directory
cd terraform

# Extract ECR repository URLs from Terraform
AWS_REGION=$(terraform output -raw aws_region)
ECR_SQS_CONSUMER_REPO=$(terraform output -raw ecr_sqs_consumer_repo_url)
ECR_SQS_PRODUCER_REPO=$(terraform output -raw ecr_sqs_producer_repo_url)
ECR_SQS_CONSUMER_REPO_NAME="${ECR_SQS_CONSUMER_REPO##*/}"
ECR_SQS_PRODUCER_REPO_NAME="${ECR_SQS_PRODUCER_REPO##*/}"
# Return to project root
cd ..
```

### Step 2: Build Docker Images

Build container images for both the SQS consumer and producer applications:

```bash
# Build SQS Consumer image
docker build \
  --platform linux/arm64 \
  --no-cache \
  --pull \
  -t ${ECR_SQS_CONSUMER_REPO}:latest \
  ./containers/sqs-consumer

# Build SQS Producer image
docker build \
  --platform linux/arm64 \
  --no-cache \
  --pull \
  -t ${ECR_SQS_PRODUCER_REPO}:latest \
  ./containers/sqs-producer
```

**Note**: The `--platform linux/arm64` flag ensures compatibility with typical EKS node architectures.

### Step 3: Authenticate with Amazon ECR

```bash
# Authenticate Docker to ECR for consumer repository
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_SQS_CONSUMER_REPO

# Authenticate Docker to ECR for producer repository
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_SQS_PRODUCER_REPO
```

**Expected output**: `Login Succeeded`

### Step 4: Push Images to ECR

```bash
# Push consumer image
docker push ${ECR_SQS_CONSUMER_REPO}:latest

# Push producer image
docker push ${ECR_SQS_PRODUCER_REPO}:latest
```

**Verify images in ECR**:

```bash
aws ecr describe-images --repository-name $ECR_SQS_CONSUMER_REPO_NAME --region $AWS_REGION --no-cli-pager
aws ecr describe-images --repository-name $ECR_SQS_PRODUCER_REPO_NAME --region $AWS_REGION --no-cli-pager
```

## Configure and Install Flux

Flux is a GitOps tool that keeps your Kubernetes cluster in sync with your Git repository. It will automatically deploy and manage both Kubernetes addons and applications.

### Step 1: Set GitHub Variables

```bash
# Replace these values with your GitHub information
export GITHUB_TOKEN='ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
export GITHUB_USER='your-github-username'
export GITHUB_OWNER='your-github-username-or-org'
export GITHUB_REPO_NAME='aws-eks-keda-sqs-lab'
```

**Security Note**: Never commit your GitHub token to version control.


### Step 2: Run Configuration Script

The `configure.sh` script updates application manifests with your specific AWS resources (ECR URLs, SQS queue names, etc.):

```bash
# Navigate to scripts directory
cd scripts

# Make script executable (if needed)
chmod +x configure.sh

# Run configuration script
./configure.sh

# Return to project root
cd ..
```

**What this script does**:

- Updates Kubernetes manifests with your ECR repository URLs
- Configures SQS queue names in application deployments
- Sets AWS region for KEDA scalers
- Updates IAM role ARNs for service accounts

![Configure Flux](./images/flux_configure.png)

### Step 3: Bootstrap Flux

Install Flux on your EKS cluster and connect it to your GitHub repository:

```bash
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_OWNER \
  --repository=$GITHUB_REPO_NAME \
  --private=false \
  --path=clusters/eks-keda-sqs-lab \
  --personal
```

**What happens during bootstrap**:

1. Flux creates a deploy key in your GitHub repository
2. Installs Flux components in the `flux-system` namespace
3. Creates a GitRepository source pointing to your repo
4. Sets up automatic reconciliation every 1 minute

![Install Flux](./images/flux_install.png)

### Step 4: Wait for Reconciliation

Flux needs 2-5 minutes to:

- Clone your Git repository
- Apply Kustomizations for infrastructure controllers
- Deploy Kubernetes addons (KEDA, Karpenter, etc.)
- Deploy your SQS applications

**Monitor Flux reconciliation**:

```bash
# Watch Flux components
watch flux get all -A

# Watch Kubernetes addons installation
watch kubectl get pods -n keda
watch kubectl get pods -n karpenter

# Watch application deployment
watch kubectl get pods -n sqs-app
```

### Step 5: Verify Installation

After reconciliation completes, verify all components are running:

```bash
# Check all Flux resources
flux get all -A

# Expected output should show all resources as "Ready"
```

All GitRepositories, HelmReleases, and Kustomizations should show status "True" or "Applied".

## Managing Flux

Flux is managed entirely through the Flux CLI. There is no web UI.

### Common Flux Commands

```bash
# View all Flux resources across all namespaces
flux get all -A

# View specific resource types
flux get sources git          # Git repositories
flux get sources helm         # Helm repositories
flux get helmreleases         # Helm releases
flux get kustomizations       # Kustomization applications

# View Flux logs
flux logs                     # All component logs
flux logs --kind=HelmRelease  # Specific resource type logs

# Force reconciliation (useful for testing)
flux reconcile source git flux-system

# Suspend reconciliation (useful during maintenance)
flux suspend kustomization apps
flux suspend helmrelease keda

# Resume reconciliation
flux resume kustomization apps
flux resume helmrelease keda

# Export current state
flux export source git flux-system
flux export kustomization apps
```

### Troubleshooting Flux Issues

```bash
# Check if Flux can reach your Git repository
flux get sources git

# Check Helm release status
flux get helmreleases -A

# View detailed events
kubectl describe kustomization apps -n flux-system
kubectl describe helmrelease keda -n flux-system

# Check Flux controller logs
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/kustomize-controller
kubectl logs -n flux-system deploy/helm-controller
```

### Additional Resources

For comprehensive Flux documentation and examples, see my three-part series:
- [Using Flux with Amazon EKS - Part 1](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson)
- [Using Flux with Amazon EKS - Part 2](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1c)
- [Using Flux with Amazon EKS - Part 3](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1f)



Follow these steps to set up the environment.

1. Set variables in "locals.tf". Below are some of the variables that should be set.

   - aws_region
   - aws_profile
   - tags
   - custom_domain_name
   - public_base_domain_name

2. Update Terraform S3 Backend in provider.tf

   - bucket
   - key
   - profile
   - dynamodb_table

3. Navigate to the Terraform directory

   ```bash
   cd terraform
   ```

4. Initialize Terraform

   ```bash
   terraform init
   ```

5. Validate the Terraform code

   ```bash
   terraform validate
   ```

6. Run, review, and save a Terraform plan

   ```bash
   terraform plan -out=plan.out
   ```

7. Apply the Terraform plan

   ```bash
   terraform apply plan.out
   ```

8. Review Terraform apply results

   ![Terraform Apply](./images/terraform_apply.png)

## Configure access to Amazon EKS Cluster

Amazon EKS Cluster details can be extracted from terraform output or by accessing the AWS Console to get the name of the cluster. This following command can be used to update the kubeconfig in your local machine where you run kubectl commands to interact with your EKS Cluster. Navigate to the root of the directory of the GitHub repo and run the following commands:

   ```bash
   cd terraform

   AWS_REGION=$(terraform output -raw aws_region)
   EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
   aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
   ```

Results of configuring kubeconfig.

![Configure Amazon EKS Cluster](./images/kubeconfig.png)

## Create and Push SQS App Docker Images to Amazon ECR

### Build the Docker Images

Set the variables needed to build and push your Docker image. Navigate to the root of the directory of the GitHub repo and run the following commands:

```bash
cd terraform

AWS_REGION=$(terraform output -raw aws_region)
ECR_SQS_CONSUMER_REPO=$(terraform output -raw ecr_sqs_consumer_repo_url)
ECR_SQS_PRODUCER_REPO=$(terraform output -raw ecr_sqs_producer_repo_url)
```

To build the Docker image, run the following command:

```bash
cd ..
docker build --platform linux/arm64 --no-cache --pull -t ${ECR_SQS_CONSUMER_REPO}:latest ./containers/sqs-consumer
docker build --platform linux/arm64 --no-cache --pull -t ${ECR_SQS_PRODUCER_REPO}:latest ./containers/sqs-producer
```

### Push the Docker Images to Amazon ECR

To push the Docker image to Amazon ECR, authenticate to your private Amazon ECR registry. To do this, run the following command:

```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_SQS_CONSUMER_REPO
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_SQS_PRODUCER_REPO
```

Once authenticated, run the following command to push your Docker image to the Amazon ECR repository:

```bash
docker push ${ECR_SQS_CONSUMER_REPO}:latest
docker push ${ECR_SQS_PRODUCER_REPO}:latest
```

## Configure and Install Flux

1. Configure Variables needed to install Flux

   ```bash
   export GITHUB_TOKEN='<REPLACE_WITH_GITHHUB_TOKEN>'
   export GITHUB_USER='<REPLACE_WITH_GITHUB_USER>'
   export GITHUB_OWNER='<REPLACE_WITH_GITHUB_OWNER>'
   export GITHUB_REPO_NAME='<REPLACE_WITH_GITHUB_REPO_NAME>'
   ```

2. Configure Flux Repository by running the "configure.sh" script. The "configure.sh" script updates the various applications with the necessary values to run correctly. Navigate to the root of the directory of the GitHub repo and run the following commands:

   ```bash
   cd scripts

   ./configure.sh
   cd ..
   ```

3. Results of running the "configure.sh" script.

   ![Configure Flux](./images/flux_configure.png)

4. Install Flux on the Amazon EKS Cluster

   ```bash
   flux bootstrap github \
     --components-extra=image-reflector-controller,image-automation-controller \
     --owner=$GITHUB_OWNER \
     --repository=$GITHUB_REPO_NAME \
     --private=false \
     --path=clusters/eks-keda-sqs-lab \
     --personal
   ```

5. Results of installing Flux on the Amazon EKS Cluster.

   ![Install Flux](./images/flux_install.png)

6. Wait 2 to 5 minutes for Flux to reconcile the Git repository we specified, During this time, Flux will install and configure all of the defined Kubernetes Addons and Applications.

7. Run the following command to check if all of the Kubernetes Addons and Applications deployed successfully

   ```bash
   flux get all -A
   ```

## Managing Flux

Managing Flux is handled by using the Flux CLI. Flux does not come with any Web or UI interface to manage Flux. Please click [here](https://fluxcd.io/flux/cmd/) if you would like more information on the Flux CLI.

The following are some commands you can use to manage Flux.

```bash
flux get all
flux get sources all|git|helm|chart
flux get helmreleases
flux get kustomizations
flux logs
flux suspend kustomization <kustomization_name>
flux reconcile source git flux-system
```

For additional information on using Flux, please look at the following series I wrote about Flux.

- [Using Flux, a GitOps Tool, with Amazon Elastic Kubernetes Service (EKS) - Part 1](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson)
- [Using Flux, a GitOps Tool, with Amazon Elastic Kubernetes Service (EKS) - Part 2](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1c)
- [Using Flux, a GitOps Tool, with Amazon Elastic Kubernetes Service (EKS) - Part 3](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1f)

## Kubernetes Addons managed by Flux

Below are the Applications that Flux manages, the Kubernetes Addons will be deployed and configured by Flux first. The following Kubernetes Addons will be installed.

- AWS Application Load Balancer Controller
- External DNS
- Karpenter
- Keda
- Metrics Server

The AWS Application Load Balancer Controller and External DNS must be deployed first because the Applications need to be accessible by a load balancer and have the DNS Name registered with Route 53.

## Applications managed by Flux

Flux can manage applications in several ways, but the most common way is through the Helm Controller. Flux will manage two Applications using Helm charts to deploy to the Amazon EKS Cluster. The two Applications are the following.

- SQS Consumer App
- SQS Producer App

## Demo

Work in Progress

```bash
kubectl get hpa -n sqs-app
kubectl scale deployment -n sqs-app sqs-producer --replicas 0
kubectl scale deployment -n sqs-app sqs-producer --replicas 1
```

## Clean Up

## Clean up Applications managed by Flux from Kubernetes

1. Suspend Applications managed by Flux

   ```bash
   flux suspend source git flux-system
   flux suspend source git sqs-app
   flux suspend kustomization apps
   ```

2. Delete Applications managed by Flux

   ```bash
   flux delete helmrelease -s sqs-app
   ```

3. Wait 1 to 5 minutes for Applications to be removed from Kubernetes

4. Delete Application sources managed by Flux

   ```bash
   flux delete source git -s sqs-app
   flux delete kustomization -s apps
   kubectl delete -n sqs-app horizontalpodautoscalers.autoscaling keda-hpa-aws-sqs-queue-scaledobject
   ```

5. Verify Applications are removed

   ```bash
   kubectl -n sqs-app get all
   kubectl -n sqs-app get ingresses
   ```

## Clean up Kubernetes Addons managed by Flux from Kubernetes

1. Suspend Kubernetes Addons managed by Flux

   ```bash
   flux suspend kustomization infra-configs
   flux suspend kustomization infra-controllers
   ```

2. Delete Kubernetes Addons managed by Flux

   ```bash
   kubectl delete $(kubectl get scaledobjects.keda.sh,scaledjobs.keda.sh -A \
     -o jsonpath='{"-n "}{.items[*].metadata.namespace}{" "}{.items[*].kind}{"/"}{.items[*].metadata.name}{"\n"}')

   flux delete kustomization -s infra-configs
   flux delete helmrelease -s aws-load-balancer-controller
   flux delete helmrelease -s external-dns
   flux delete helmrelease -s karpenter
   flux delete helmrelease -s keda
   flux delete helmrelease -s metrics-server
   kubectl patch crd ec2nodeclasses.karpenter.k8s.aws -p '{"metadata":{"finalizers":[]}}' --type=merge
   ```

3. Wait 1 to 5 minutes for Kubernetes Addons to be removed from Kubernetes

4. Delete Application sources managed by Flux

   ```bash
   kubectl patch crd ec2nodeclasses.karpenter.k8s.aws -p '{"metadata":{"finalizers":[]}}' --type=merge
   flux delete source helm -s eks-charts
   flux delete source helm -s external-dns
   flux delete source helm -s karpenter
   flux delete source helm -s keda
   flux delete source helm -s metrics-server
   flux delete kustomization -s infra-controllers
   ```

5. Verify Kubernetes Addons were removed successfully

   ```bash
   kubectl -n kube-system get all -l app.kubernetes.io/name=external-dns
   kubectl -n kube-system get all -l app.kubernetes.io/name=aws-load-balancer-controller
   kubectl -n kube-system get all -l app.kubernetes.io/name=aws-cluster-autoscaler
   kubectl -n kube-system get all -l app.kubernetes.io/name=metrics-server
   kubectl -n karpenter get all
   kubectl -n keda get all
   kubectl get ingressclasses -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

6. If any resources are not deleted, manually delete them.

## Uninstall Flux from Kubernetes

1. Uninstall Flux

   ```bash
   flux uninstall -s
   ```

2. Verify Flux was removed successfully

   ```bash
   kubectl get all -n flux-system
   ```

## Clean up Terraform

1. Navigate to the root of the directory of the GitHub repo and run the following commands

   ```bash
   cd terraform

   terraform destroy
   ```

2. Check Terraform destroy results

   ![Terraform Destroy](./images/terraform_destroy.png)

## Conclusion

In conclusion, this guide provided a comprehensive overview of utilizing Keda and Amazon EKS.

## 🗟️ License

MIT License © 2025 [Dallin Rasmuson](https://www.linkedin.com/in/dallinrasmuson)
