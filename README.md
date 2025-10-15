# Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)

![Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)](./images/aws_eks_keda_sqs.png)

[![Terraform](https://img.shields.io/badge/Terraform-%5E1.10-blue)](https://developer.hashicorp.com/terraform)
[![KEDA](https://img.shields.io/badge/KEDA-v2.x-green)](https://keda.sh/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![FluxCD](https://img.shields.io/badge/FluxCD-GitOps-lightblue)](https://fluxcd.io/)

## Table of Contents

1. [Introduction](#introduction)
2. [What is Kubernetes Event-driven Autoscaling (KEDA)?](#what-is-kubernetes-event-driven-autoscaling-keda)
3. [Architecture Overview](#architecture-overview)
4. [How This Demo Works](#how-this-demo-works)
5. [Prerequisites](#prerequisites)
6. [Setup and Deploy Infrastructure](#setup-and-deploy-infrastructure)
7. [Configure Access to Amazon EKS Cluster](#configure-access-to-amazon-eks-cluster)
8. [Create and Push SQS App Docker Images to Amazon ECR](#create-and-push-sqs-app-docker-images-to-amazon-ecr)
9. [Configure and Install Flux](#configure-and-install-flux)
10. [Managing Flux](#managing-flux)
11. [Kubernetes Addons Managed by Flux](#kubernetes-addons-managed-by-flux)
12. [Applications Managed by Flux](#applications-managed-by-flux)
13. [Demo: See KEDA Autoscaling in Action](#demo-see-keda-autoscaling-in-action)
14. [Troubleshooting](#troubleshooting)
15. [Security Considerations](#security-considerations)
16. [Clean Up](#clean-up)
17. [Conclusion](#conclusion)

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

### Flux Additional Resources

For comprehensive Flux documentation and examples, see my three-part series:
- [Using Flux with Amazon EKS - Part 1](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson)
- [Using Flux with Amazon EKS - Part 2](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1c)
- [Using Flux with Amazon EKS - Part 3](https://www.linkedin.com/pulse/using-flux-gitops-tool-amazon-elastic-kubernetes-service-rasmuson-1f)


## Kubernetes Addons Managed by Flux

Flux automatically installs and manages the following Kubernetes addons. These are deployed before applications to ensure necessary infrastructure is in place.

### AWS Load Balancer Controller

- **Purpose**: Provisions AWS Application Load Balancers for Kubernetes Ingress resources
- **Namespace**: `kube-system`
- **Why needed**: Exposes applications externally with native AWS load balancing

### External DNS

- **Purpose**: Automatically creates Route 53 DNS records for Ingress and Service resources
- **Namespace**: `kube-system`
- **Why needed**: Makes applications accessible via human-readable domain names

### Karpenter

- **Purpose**: Just-in-time node provisioning based on pod requirements
- **Namespace**: `karpenter`
- **Why needed**: Automatically scales EKS nodes to handle varying workloads efficiently

### KEDA (Kubernetes Event-Driven Autoscaling)

- **Purpose**: Scales applications based on external event sources like SQS queues
- **Namespace**: `keda`
- **Why needed**: Core component enabling event-driven autoscaling for this demo

### Metrics Server

- **Purpose**: Provides resource utilization metrics for pods and nodes
- **Namespace**: `kube-system`
- **Why needed**: Enables kubectl top commands and resource-based autoscaling

**Verify addon installation**:

```bash
# Check all addon pods are running
kubectl get pods -n keda
kubectl get pods -n karpenter
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
```

## Applications Managed by Flux

Flux manages two applications deployed via Helm charts. These work together to demonstrate KEDA's autoscaling capabilities.

### SQS Producer Application

- **Purpose**: Continuously sends messages to the SQS queue at a configurable rate
- **Namespace**: `sqs-app`
- **Configuration**: Message rate, batch size, and queue name
- **Deployment**: Single pod (does not scale)

### SQS Consumer Application

- **Purpose**: Processes messages from the SQS queue
- **Namespace**: `sqs-app`
- **Scaling**: Managed by KEDA based on queue depth
- **Configuration**: Queue polling, message processing logic
- **Scale range**: 0 to 30 pods (configurable)

**View application status**:

```bash
# Check application pods
kubectl get pods -n sqs-app

# Check KEDA ScaledObject
kubectl get scaledobjects -n sqs-app

# Check HPA created by KEDA
kubectl get hpa -n sqs-app

# View application logs
kubectl logs -n sqs-app -l app=sqs-consumer
kubectl logs -n sqs-app -l app=sqs-producer
```

## Demo: See KEDA Autoscaling in Action

This section demonstrates KEDA's autoscaling behavior by controlling message flow into the SQS queue and observing how the consumer pods scale in response.

### Initial State Verification

Before starting, verify your initial state:

```bash
# Check current pod count
kubectl get pods -n sqs-app

# Check HPA status
kubectl get hpa -n sqs-app

# Check SQS queue depth
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw sqs_queue_url) \
  --attribute-names ApproximateNumberOfMessages
```

**Expected initial state**: 0 consumer pods (scaled to zero), 1 producer pod (paused or stopped)

### Step 1: Start Message Production

Scale up the producer to begin sending messages to SQS:

```bash
# Start the SQS producer
kubectl scale deployment sqs-producer -n sqs-app --replicas=1

# Monitor producer logs to confirm messages are being sent
kubectl logs -n sqs-app -l app=sqs-producer -f
```

**What to observe**: Producer logs showing messages being sent to SQS queue.

### Step 2: Watch KEDA Trigger Scaling

In a new terminal, monitor the scaling activity:

```bash
kubectl get hpa -n sqs-app
kubectl scale deployment -n sqs-app sqs-producer --replicas 0
kubectl scale deployment -n sqs-app sqs-producer --replicas 1

# Watch pods in real-time
watch kubectl get pods -n sqs-app

# In another terminal, watch HPA
watch kubectl get hpa -n sqs-app
```

**What happens**:

1. Messages accumulate in SQS queue
2. KEDA polls the queue every 30 seconds
3. When queue depth exceeds threshold (5 messages/pod), KEDA triggers scaling
4. Consumer pods are created (1-2 pods initially)
5. More pods are added as queue depth increases
6. Pods start processing and removing messages from the queue

**Timeline**:

- **0-30s**: Messages accumulate in queue, no pods yet
- **30-60s**: KEDA detects messages, triggers first pod creation
- **1-3 min**: Pods scale up to handle queue depth
- **5-10 min**: Steady state with consistent message processing

### Step 3: Observe Scaling Metrics

```bash
# Check current replica count
kubectl get hpa -n sqs-app -w

# View KEDA scaler metrics
kubectl describe scaledobject sqs-consumer -n sqs-app

# Check SQS queue depth over time
while true; do
  echo "Queue depth: $(aws sqs get-queue-attributes \
    --queue-url $(cd terraform && terraform output -raw sqs_queue_url) \
    --attribute-names ApproximateNumberOfMessages \
    --query 'Attributes.ApproximateNumberOfMessages' \
    --output text)"
  sleep 10
done
```

**Expected output**:

```bash
NAME           REFERENCE              TARGETS    MINPODS   MAXPODS   REPLICAS
sqs-consumer   Deployment/sqs-consumer   150/5      0         30        10
```

This shows 150 messages in queue, target of 5 per pod, resulting in 10 active replicas.

### Step 4: Stop Message Production

Stop sending messages and watch the scale-down behavior:

```bash
# Stop the producer
kubectl scale deployment sqs-producer -n sqs-app --replicas=0

# Continue watching pods
watch kubectl get pods -n sqs-app
```

**What happens**:

1. No new messages are added to the queue
2. Consumer pods continue processing remaining messages
3. Queue depth decreases as messages are processed
4. KEDA gradually scales down the number of pods
5. After cooldown period (5 minutes by default) with empty queue, pods scale to zero

**Timeline**:

- **0-5 min**: Pods process remaining messages, queue empties
- **5-10 min**: Cooldown period, no new messages
- **10+ min**: All consumer pods terminated (scale to zero)

### Step 5: Verify Scale-to-Zero

```bash
# Confirm queue is empty
aws sqs get-queue-attributes \
  --queue-url $(cd terraform && terraform output -raw sqs_queue_url) \
  --attribute-names ApproximateNumberOfMessages

# Confirm no consumer pods running
kubectl get pods -n sqs-app

# Check HPA shows 0 replicas
kubectl get hpa -n sqs-app
```

**Expected output**:

- Queue: 0 messages
- Consumer pods: None
- HPA: 0/0 replicas

### Step 6: Test Rapid Scale-Up

Restart the producer with higher message rate to see rapid scaling:

```bash
# Scale producer back up
kubectl scale deployment sqs-producer -n sqs-app --replicas=1

# Watch for rapid pod creation
watch kubectl get pods -n sqs-app
```

**What to observe**: Pods scale from 0 to multiple replicas within 1-2 minutes as messages accumulate.

### Understanding KEDA Scaling Behavior

**Scaling Formula**:

```
Desired Replicas = ceil(Queue Depth / Target Messages Per Pod)
```

**Example**:

- Queue has 50 messages
- Target is 5 messages per pod
- KEDA creates: ceil(50/5) = 10 consumer pods

**Scale-Up Characteristics**:

- Triggered immediately when queue depth exceeds threshold
- Aggressive scaling to handle backlog quickly
- Limited by `maxReplicaCount` setting

**Scale-Down Characteristics**:

- Gradual scale-down as queue empties
- Cooldown period prevents thrashing
- Scale-to-zero only after sustained idle period

### Optional: Advanced Monitoring with k9s

If you have k9s installed, use it for better visualization:

```bash
# Launch k9s
k9s

# Navigate to:
# - :pods and filter by namespace :sqs-app
# - :hpa to see horizontal pod autoscaler
# - :describe to view KEDA ScaledObject details
```

## Clean Up

**Important**: Follow these steps in order to avoid orphaned resources and potential costs.

### Step 1: Suspend Flux Reconciliation

Prevent Flux from recreating resources during cleanup:

```bash
# Suspend all Flux sources and Kustomizations
flux suspend source git flux-system
flux suspend source git sqs-app
flux suspend kustomization infra-configs
flux suspend kustomization infra-controllers
flux suspend kustomization apps
```

### Step 2: Remove Applications

```bash
# Delete application Helm releases
flux delete helmrelease sqs-app --silent

# Delete Keda HPA Autoscaling
kubectl delete -n sqs-app horizontalpodautoscalers.autoscaling keda-hpa-aws-sqs-queue-scaledobject

# Wait for applications to terminate (1-5 minutes)
echo "Waiting for application removal..."
sleep 120

# Delete application sources
flux delete source git sqs-app --silent
flux delete kustomization apps --silent

# Verify applications removed
kubectl get -n sqs-app all
kubectl get -n sqs-app ingress
```

**Expected result**: No resources in `sqs-app` namespace

### Step 3: Remove Kubernetes Addons

```bash
# Delete any KEDA-managed resources first
kubectl delete scaledobjects --all -A
kubectl delete scaledjobs --all -A

# Delete addon Helm releases
flux delete helmrelease aws-load-balancer-controller --silent
flux delete helmrelease external-dns --silent
flux delete helmrelease karpenter --silent
flux delete helmrelease keda --silent
flux delete helmrelease metrics-server --silent

# Cleanup Keda CRDs
kubectl patch crd ec2nodeclasses.karpenter.k8s.aws -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete $(kubectl get scaledobjects.keda.sh,scaledjobs.keda.sh -A \
   -o jsonpath='{"-n "}{.items[*].metadata.namespace}{" "}{.items[*].kind}{"/"}{.items[*].metadata.name}{"\n"}')

# Wait for addons to terminate (2-5 minutes)
echo "Waiting for addon removal..."
sleep 120

# Delete addon sources
flux delete kustomization infra-configs --silent
flux delete source helm eks-charts --silent
flux delete source helm external-dns --silent
flux delete source helm karpenter --silent
flux delete source helm keda --silent
flux delete source helm metrics-server --silent
flux delete kustomization infra-controllers --silent
```

**Verify addon removal**:

```bash
kubectl get -n kube-system all -l app.kubernetes.io/name=external-dns
kubectl get -n kube-system all -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get -n kube-system all -l app.kubernetes.io/name=aws-cluster-autoscaler
kubectl get -n kube-system all -l app.kubernetes.io/name=metrics-server
kubectl get -n karpenter all
kubectl get -n keda all
kubectl get ingressclasses -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Expected result**: No addon pods running

### Step 4: Manual Resource Cleanup (If Needed)

If any resources remain after addon removal:

```bash
# List remaining Ingresses and delete manually
kubectl get ingress -A
kubectl delete ingress <ingress-name> -n <namespace>

# List remaining Services with LoadBalancer type
kubectl get svc -A | grep LoadBalancer
kubectl delete svc <service-name> -n <namespace>

# Check for remaining KEDA resources
kubectl get scaledobjects -A
kubectl get scaledjobs -A
kubectl delete scaledobject <name> -n <namespace>
```

### Step 5: Uninstall Flux

```bash
# Uninstall Flux from cluster
flux uninstall --silent

# Verify Flux removed
kubectl get -n flux-system all
```

**Expected result**: `No resources found in flux-system namespace.`

### Step 6: Destroy Terraform Infrastructure

```bash
# Navigate to Terraform directory
cd terraform

# Destroy all AWS resources
terraform destroy

# Confirm destruction when prompted
# Type 'yes' to proceed
```

**Destruction timeline**: 15-20 minutes

![Terraform Destroy](./images/terraform_destroy.png)

**Resources destroyed**:

- EKS cluster and node groups
- VPC, subnets, NAT gateways
- ECR repositories
- SQS queue
- IAM roles and policies
- KMS keys
- Route 53 records
- ACM certificates

## Conclusion

This guide demonstrated how to implement a production-ready, event-driven autoscaling solution using KEDA with Amazon EKS. You learned how to:

- Deploy a complete EKS infrastructure using Terraform
- Implement GitOps workflows with Flux for continuous deployment
- Configure KEDA to scale applications based on AWS SQS queue depth
- Achieve cost optimization through scale-to-zero capabilities
- Manage Kubernetes addons and applications declaratively

### Key Takeaways

**Event-Driven Autoscaling**: KEDA extends Kubernetes autoscaling beyond CPU and memory metrics, enabling applications to scale based on real business events like message queue depth, database queries, or custom metrics.

**Scale-to-Zero Economics**: By scaling to zero during idle periods, you pay only for compute resources when actively processing events, significantly reducing costs for sporadic or batch workloads.

**GitOps Best Practices**: Flux provides automated, declarative infrastructure management, ensuring your cluster state always matches your Git repository and enabling easy rollbacks and auditing.

**AWS Integration**: KEDA's native support for AWS services like SQS, combined with EKS's managed Kubernetes experience, creates a powerful platform for cloud-native applications.

### Next Steps

**Production Hardening**:

- Implement comprehensive monitoring with Prometheus and Grafana
- Set up alerting for scaling events and failures
- Configure pod disruption budgets for high availability
- Implement service mesh (Istio/Linkerd) for advanced traffic management

**Scaling Optimizations**:

- Fine-tune KEDA trigger thresholds based on your workload
- Adjust cooldown periods to prevent scaling thrashing
- Configure multiple KEDA scalers for complex event sources
- Implement custom metrics for business-specific scaling triggers

**Security Enhancements**:

- Enable Pod Security Standards at cluster level
- Implement network policies for zero-trust networking
- Set up AWS GuardDuty for threat detection
- Configure AWS Config for compliance monitoring

**Advanced Features**:

- Explore KEDA ScaledJobs for batch processing
- Implement multi-queue processing with different scalers
- Add circuit breakers for downstream service protection
- Configure priority classes for critical workloads

### Additional Resources

- **KEDA Documentation**: [https://keda.sh/docs/](https://keda.sh/docs/)
- **Flux Documentation**: [https://fluxcd.io/docs/](https://fluxcd.io/docs/)
- **AWS EKS Best Practices**: [https://aws.github.io/aws-eks-best-practices/](https://aws.github.io/aws-eks-best-practices/)
- **Karpenter Documentation**: [https://karpenter.sh/docs/](https://karpenter.sh/docs/)

Thank you for following this guide. For questions, issues, or contributions, please visit the [GitHub repository](https://github.com/junglekid/aws-eks-keda-sqs-lab).

## 🗟️ License

MIT License © 2025 [Dallin Rasmuson](https://www.linkedin.com/in/dallinrasmuson)
