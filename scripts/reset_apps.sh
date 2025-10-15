#!/usr/bin/env bash

echo "Resetting Apps managed by FluxCD..."
echo ""

cd ..

# SQS App
cp -f ./k8s/templates/apps/sqs-app/config.yaml ./k8s/apps/sqs-app/config.yaml
cp -f ./k8s/templates/apps/sqs-app/release.yaml ./k8s/apps/sqs-app/release.yaml
cp -f ./k8s/templates/apps/sqs-app/repository.yaml ./k8s/apps/sqs-app/repository.yaml

# AWS Load Balancer
cp -f ./k8s/templates/infrastructure/controllers/aws-load-balancer-controller/release.yaml ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml

# External DNS
cp -f ./k8s/templates/infrastructure/controllers/external-dns/release.yaml ./k8s/infrastructure/controllers/external-dns/release.yaml

# Karpenter
cp -f ./k8s/templates/infrastructure/configs/karpenter/config.yaml ./k8s/infrastructure/configs/karpenter/config.yaml

cp -f ./k8s/templates/infrastructure/controllers/karpenter/release.yaml ./k8s/infrastructure/controllers/karpenter/release.yaml

echo "Pushing changes to Git repository..."
echo ""

# Add SQS App files
git add ./k8s/apps/sqs-app/config.yaml
git add ./k8s/apps/sqs-app/release.yaml
git add ./k8s/apps/sqs-app/repository.yaml

# Add Infrastructure Controller files
git add ./k8s/infrastructure/controllers/aws-load-balancer-controller/release.yaml
git add ./k8s/infrastructure/controllers/external-dns/release.yaml
git add ./k8s/infrastructure/configs/karpenter/config.yaml
git add ./k8s/infrastructure/controllers/karpenter/release.yaml

git commit -m "Resetting Apps"
git push &> /dev/null

echo ""
echo "Finished Resetting Apps managed by FluxCD..."
