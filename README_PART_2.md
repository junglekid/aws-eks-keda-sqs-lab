# Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS) - Part 2: Architecture and Infrastructure Setup

![Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)](./images/aws_eks_keda_sqs.png)

[![Terraform](https://img.shields.io/badge/Terraform-%5E1.10-blue)](https://developer.hashicorp.com/terraform)
[![KEDA](https://img.shields.io/badge/KEDA-v2.x-green)](https://keda.sh/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![FluxCD](https://img.shields.io/badge/FluxCD-GitOps-lightblue)](https://fluxcd.io/)

## Welcome Back!

In [Part 1](https://www.linkedin.com/pulse/using-keda-scale-aws-sqs-amazon-elastic-kubernetes-service-rasmuson-sebec/) or [Part 1](https://medium.com/@junglekid_40016/using-keda-to-scale-aws-sqs-with-amazon-elastic-kubernetes-service-eks-part-1-introduction-3b58f7920f32),  we explored what KEDA is, why it's essential for event-driven autoscaling on Kubernetes, and reviewed the architecture of our complete solution. Now it's time to build the infrastructure.

In this article, you'll:

- Set up prerequisites and install required tools
- Deploy the infrastructure with Terraform
- Configure access to the EKS cluster
- Build and push Docker images to Amazon ECR
- Configure and install Flux for GitOps
- Deploy applications and Kubernetes addons

Let's dive in!

---

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

**Important**: Save your token securely—you'll need it during Flux installation.

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

---

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
# Navigate to Terraform directory
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

---

## Configure Access to Amazon EKS Cluster

Update your local kubeconfig to access the newly created EKS cluster:

```bash
# Navigate to the Terraform directory
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

---

## Create and Push SQS App Docker Images to Amazon ECR

### Step 1: Set Environment Variables

```bash
# Navigate to Terraform directory
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
# Navigate to the scripts directory
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

![Install Flux](./images/flux_install.png)

### Step 4: Wait for Reconciliation

Flux needs 2-10 minutes to:

- Clone your Git repository
- Apply Kustomizations for infrastructure controllers
- Deploy Kubernetes addons (KEDA, Karpenter, etc.)
- Deploy your SQS applications

**Monitor Flux reconciliation**:

**NOTE:** `watch` is not installed by default on macOS. If `homebrew` is installed, `watch` can be installed by running `brew install watch`.

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

---

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

# Force reconciliation (practical for testing)
flux reconcile source git flux-system

# Suspend reconciliation (applicable during maintenance)
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

Flux automatically installs and manages the following Kubernetes addons. These are deployed before applications to ensure the necessary infrastructure is in place.

### AWS Load Balancer Controller

- **Purpose**: Provision AWS Application Load Balancers for Kubernetes Ingress resources
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

---

## Applications Managed by Flux

Flux manages two applications deployed via Helm charts. These work together to demonstrate KEDA's autoscaling capabilities.

### SQS Producer Application

- **Purpose**: Sends messages to the SQS queue from a website
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
kubectl logs -n sqs-app -l name=sqs-consumer
kubectl logs -n sqs-app -l name=sqs-producer
```

---

## What We've Accomplished

At this point, you have:

✅ **Infrastructure**: Complete EKS cluster deployed with Terraform
✅ **GitOps**: Flux managing all Kubernetes resources
✅ **Addons**: KEDA, Karpenter, AWS LB Controller installed
✅ **Applications**: SQS producer and consumer ready
✅ **Security**: IAM roles, encryption, and security groups configured
✅ **Monitoring**: Metrics Server providing resource metrics

---

## What's Next?

In **Part 3**, we'll see KEDA in action:

- Live autoscaling demonstration from 0 to 30+ pods
- Monitoring scaling behavior with k9s and kubectl
- Understanding scaling triggers and cooldown periods
- Clean up and resource removal

**The infrastructure is ready. Now let's watch it scale!**

---

**Found this helpful? Like, comment, and share!**

**Questions about the setup? Drop them in the comments below.**

---

## 🗟️ License

MIT License © 2025 [Dallin Rasmuson](https://www.linkedin.com/in/dallinrasmuson)

#Kubernetes #AWS #EKS #KEDA #CloudNative #DevOps #Terraform #FluxCD #GitOps #InfrastructureAsCode #CloudArchitecture #SRE
