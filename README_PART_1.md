# Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS) - Part 1: Introduction and Understanding KEDA

![Using KEDA to Scale AWS SQS with Amazon Elastic Kubernetes Service (EKS)](./images/aws_eks_keda_sqs.png)

[![Terraform](https://img.shields.io/badge/Terraform-%5E1.10-blue)](https://developer.hashicorp.com/terraform)
[![KEDA](https://img.shields.io/badge/KEDA-v2.x-green)](https://keda.sh/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![FluxCD](https://img.shields.io/badge/FluxCD-GitOps-lightblue)](https://fluxcd.io/)

## Introduction

This guide demonstrates how to implement event-driven autoscaling for AWS SQS message processing using KEDA (Kubernetes Event-driven Autoscaling) on Amazon EKS. You'll learn how to automatically scale your Kubernetes workloads from zero to hundreds of pods based on the number of messages in an SQS queue, then scale back down to zero when the queue is empty.

**What You'll Build**: A complete infrastructure that processes messages from an AWS SQS queue using Kubernetes pods that automatically scale based on queue depth. When messages arrive, KEDA triggers the creation of a pod. When the queue empties, pods scale down to zero, saving costs.

This is Part 1 of a 3-part series:

- **Part 1 (this article)**: Introduction and understanding KEDA
- **Part 2**: Architecture overview and infrastructure setup
- **Part 3**: Demo, managing the system, and cleanup

You can access the complete code in my [GitHub Repository](https://github.com/junglekid/aws-eks-keda-sqs-lab).

---

## What is Kubernetes Event-driven Autoscaling (KEDA)?

[KEDA](https://keda.sh/) is an application-level autoscaler for Kubernetes workloads. It extends the basic autoscaling capabilities provided by Kubernetes, enabling you to scale applications in response to real-time events rather than just metrics such as CPU or memory usage. Here are the key features and concepts of KEDA:

### Key Features

**Event-Driven**: KEDA scales applications based on events from various sources, such as message queues, databases, timers, and other event sources that can provide metrics. This enables more dynamic, responsive scaling than traditional metric-based autoscaling.

**Support for Multiple Event Sources**: KEDA supports a wide range of event sources, including popular message queues such as Kafka, RabbitMQ, Azure Service Bus, AWS SQS, and more. It can also integrate with custom event sources.

**Seamless Integration with Kubernetes**: KEDA is implemented as a Kubernetes Operator, enabling seamless integration with the Kubernetes ecosystem. It extends Kubernetes by adding new custom resources that define how applications should scale in response to events.

**ScaledObject Custom Resource**: The key custom resource in KEDA is the `ScaledObject`. This resource defines how a particular deployment or job should scale in response to events. You specify the target event source, the scaling triggers, and other scaling parameters in a `ScaledObject`.

**Scale-to-Zero**: One of KEDA's unique features is its ability to scale workloads down to zero pods. This means that when there are no events to process, the application can release all its resources, leading to cost savings, especially in cloud environments.

**Horizontal Pod Autoscaler (HPA) Integration**: KEDA can work in conjunction with Kubernetes' built-in Horizontal Pod Autoscaler. It activates the HPA based on event metrics, enabling a more dynamic, responsive autoscaling mechanism.

**Flexible and Extensible**: KEDA is designed to be extensible, allowing for the addition of new scalers (event sources) as needed. Its architecture is modular, which makes it easier to extend and adapt to specific needs.

KEDA is particularly useful for applications that need to respond quickly to fluctuating workloads, such as those that process events from message queues or respond to real-time data streams. Its ability to scale to zero also makes it an attractive option for cost optimization in cloud-native environments.

![KEDA Architecture](./images/keda_arch.png)

### Benefits of using KEDA with Amazon EKS

Using Kubernetes Event-driven Autoscaling (KEDA) with Amazon Elastic Kubernetes Service (EKS) offers several benefits, particularly for organizations looking to build and manage scalable, event-driven applications in the cloud. Here are some of the key advantages:

**Efficient Resource Utilization**: KEDA's ability to scale applications based on actual demand, including scaling to zero, ensures efficient resource utilization. This is particularly beneficial in a cloud environment like EKS, where resource usage directly impacts costs.

**Enhanced Scalability for Event-Driven Workloads**: EKS provides a robust platform for running Kubernetes workloads, and KEDA further enhances it by enabling more responsive, dynamic scaling based on events. This is ideal for event-driven workloads, such as processing messages from queues or reacting to database changes.

**Cost-Effective**: By scaling workloads to zero when not in use, KEDA helps to reduce costs. In an EKS environment, where you pay for the resources you use, this can lead to significant savings, especially for workloads with variable or sporadic traffic patterns.

**Seamless Integration**: KEDA integrates with EKS, enabling easy deployment and management of event-driven autoscaling. This integration simplifies the operational complexity and reduces the effort required to manage application scaling.

**Support for a Wide Range of Event Sources**: KEDA supports a wide range of event sources, including those commonly used in AWS environments, such as Amazon SQS, SNS, and CloudWatch. This makes it versatile and suitable for various EKS application scenarios.

**Improved Application Performance and Responsiveness**: By automatically scaling based on real-time events, applications can maintain optimal performance levels, responding efficiently to spikes in demand without manual intervention.

**Flexibility and Customization**: KEDA enables granular customization of scaling rules and triggers, allowing teams to tailor scaling behavior to their application's specific needs and traffic patterns.

**Simplified DevOps Processes**: With KEDA handling the complexity of event-driven autoscaling, DevOps teams can focus more on other aspects of application development and infrastructure management, improving overall operational efficiency.

**Better Use of EKS Features**: KEDA complements EKS's existing features — such as network policies, security groups, and load balancing — ensuring autoscaling is not only practical but also secure and well-integrated with the overall infrastructure.

**Community and Ecosystem Support**: Being an open-source project, KEDA benefits from strong community support and continuous development. This ensures compatibility with the latest Kubernetes features and trends, which is crucial for maintaining a modern cloud-native infrastructure on EKS.

In summary, integrating KEDA with EKS enhances Kubernetes's ability to handle event-driven, dynamic workloads in a cloud environment, leading to improved performance, cost efficiency, and operational simplicity.

---

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

---

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

- **Trigger**: AWS SQS queue with a specific queue name and region
- **Queue Length Target**: Number of messages per pod (e.g., 10 messages per pod)
- **Min Replicas**: 0 (allows scale-to-zero)
- **Max Replicas**: Configurable upper limit (e.g., 30 pods)
- **Polling Interval**: How often KEDA checks the queue (e.g., every 30 seconds)
- **Cooldown Period**: Time to wait before scaling down (e.g., 300 seconds)

This configuration ensures efficient processing while preventing over-scaling and managing costs.

---

## What's Coming Next

In **Part 2**, we'll explore:

- Prerequisites and tool installation
- Complete setup and deployment instructions with Terraform
- Configuring and installing Flux for GitOps
- Building and pushing Docker images to ECR
- Managing Flux and deployed applications

In **Part 3**, we'll demonstrate:

- Live autoscaling demo from 0 to 10+ pods
- Managing Flux and Kubernetes resources
- Monitoring and observability techniques
- Clean up and resource removal

---

## Getting Started

The complete code for this series is available in my [GitHub Repository](https://github.com/junglekid/aws-eks-keda-sqs-lab).

**Prerequisites you'll need for following along**:

- AWS account with administrative access
- GitHub account for GitOps repository
- Basic Kubernetes knowledge
- Familiarity with Terraform (helpful but not required)
- Docker installed locally

---

## Key Takeaways

1. **KEDA extends Kubernetes autoscaling** beyond CPU/memory to real business events
2. **Scale-to-zero capability** dramatically reduces costs for event-driven workloads
3. **50+ built-in scalers** support AWS, Azure, GCP, and custom metrics
4. **Zero application code changes** required—just YAML configurations
5. **Production-ready** with high availability, security, and observability

## Conclusion

KEDA represents a paradigm shift in how we think about autoscaling cloud-native applications. Instead of scaling based on resource utilization (a lagging indicator), we scale based on actual business events (a leading indicator).

The combination of KEDA with Amazon EKS creates a powerful platform that's:

- **Responsive**: React instantly to business events
- **Efficient**: Scale to zero when idle
- **Cost-effective**: Pay only for what you use
- **Simple**: Manage through declarative YAML
- **Production-ready**: Enterprise-grade reliability

In part 2, we'll dive into the architecture and step-by-step setup of the complete infrastructure. You'll see exactly how to deploy a production-ready KEDA solution on AWS EKS using infrastructure as code.

**Stay tuned for Part 2, where we'll build the entire infrastructure from scratch!**

---

**Found this helpful? Please like, comment, and share with your network!**

**Have questions about KEDA or Kubernetes autoscaling? Drop them in the comments below.**

---

## 🗟️ License

MIT License © 2025 [Dallin Rasmuson](https://www.linkedin.com/in/dallinrasmuson)

#Kubernetes #AWS #EKS #KEDA #CloudNative #DevOps #Autoscaling #CloudComputing #Infrastructure #GitOps #Terraform #SRE #CloudArchitecture
