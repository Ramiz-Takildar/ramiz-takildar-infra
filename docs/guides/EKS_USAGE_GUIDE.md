# EKS Module Usage Guide

> **Complete guide for deploying and managing Amazon EKS clusters using the Infrastructure Provisioning Platform**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Options](#configuration-options)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [Common Use Cases](#common-use-cases)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Overview

The EKS module provisions a production-ready Amazon Elastic Kubernetes Service (EKS) cluster with:

- **Managed Control Plane**: AWS-managed Kubernetes control plane
- **Managed Node Groups**: Auto-scaling EC2 worker nodes
- **Fargate Support**: Serverless compute for pods
- **IRSA**: IAM Roles for Service Accounts
- **Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- **Security**: KMS encryption, security groups, IAM roles
- **Monitoring**: CloudWatch logs and metrics

## Prerequisites

### 1. AWS Resources Required

Before deploying an EKS cluster, ensure you have:

- ✅ **VPC with Private Subnets**: At least 2 subnets in different AZs
- ✅ **NAT Gateway**: For private subnet internet access
- ✅ **AWS OIDC Provider**: Configured for GitHub Actions
- ✅ **IAM Role**: With EKS permissions for GitHub Actions

### 2. Deploy VPC First

If you don't have a VPC, deploy one first:

```bash
# Go to GitHub Actions → VPC Infrastructure
# Run workflow with:
- Action: apply
- Environment: dev
- VPC Name: eks-vpc
- VPC CIDR: 10.0.0.0/16
- Availability Zones: 3
- Create NAT Gateway: true
```

### 3. GitHub Secrets Required

Ensure these secrets are configured in your repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `VPC_ID` | VPC ID for EKS | `vpc-0123456789abcdef0` |
| `PRIVATE_SUBNET_IDS` | Private subnet IDs (JSON array) | `["subnet-xxx", "subnet-yyy", "subnet-zzz"]` |

### 4. Local Tools (for post-deployment)

- **kubectl**: >= 1.28
- **AWS CLI**: >= 2.0
- **helm**: >= 3.0 (optional)

## Quick Start

### 5-Minute Deployment

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → EKS Infrastructure
   ```

2. **Click "Run workflow"**

3. **Use these settings for a basic cluster**:
   ```yaml
   Action: apply
   Environment: dev
   Cluster Name: my-first-eks
   Kubernetes Version: 1.28
   Instance Types: t3.medium
   Desired Size: 2
   Min Size: 1
   Max Size: 4
   Enable Fargate: false
   ```

4. **Click "Run workflow"** and wait (~15-20 minutes)

5. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name my-first-eks
   kubectl get nodes
   ```

## Step-by-Step Deployment

### Step 1: Access GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **"EKS Infrastructure"** from the workflows list

### Step 2: Start Workflow

1. Click the **"Run workflow"** button (top right)
2. A form will appear with deployment options

### Step 3: Configure Basic Settings

#### Action Selection
```
Action: apply
```
- **plan**: Preview changes without applying
- **apply**: Create/update the cluster
- **destroy**: Delete the cluster

#### Environment Selection
```
Environment: dev
```
- **dev**: Development (no approval required)
- **staging**: Staging (optional approval)
- **prod**: Production (requires approval from 2+ reviewers)

#### Cluster Configuration
```
Cluster Name: production-eks
Kubernetes Version: 1.28
```

**Cluster Name Rules**:
- Must start with a letter
- Can contain letters, numbers, and hyphens
- Must be unique in your AWS account/region

**Kubernetes Versions**:
- `1.28`: Latest stable (recommended)
- `1.27`: Previous stable
- `1.26`: Older stable

### Step 4: Configure Node Groups

#### Instance Types
```
Instance Types: t3.medium,t3.large
```

**Common Instance Types**:
- **t3.micro**: 2 vCPU, 1 GB RAM (dev/test only)
- **t3.small**: 2 vCPU, 2 GB RAM (light workloads)
- **t3.medium**: 2 vCPU, 4 GB RAM (general purpose)
- **t3.large**: 2 vCPU, 8 GB RAM (moderate workloads)
- **m5.large**: 2 vCPU, 8 GB RAM (balanced)
- **m5.xlarge**: 4 vCPU, 16 GB RAM (production)
- **r5.large**: 2 vCPU, 16 GB RAM (memory-intensive)

**Multiple Instance Types**:
- Separate with commas: `t3.medium,t3.large,t3a.medium`
- Enables Spot instance flexibility
- Improves availability

#### Node Scaling
```
Desired Size: 3
Min Size: 2
Max Size: 6
```

**Sizing Guidelines**:
- **Dev**: Min=1, Desired=2, Max=3
- **Staging**: Min=2, Desired=3, Max=5
- **Production**: Min=3, Desired=4, Max=10

**Considerations**:
- Each node can run ~30 pods (default)
- Reserve capacity for system pods
- Plan for peak load + 20% buffer

### Step 5: Configure Fargate (Optional)

```
Enable Fargate: true
```

**When to Use Fargate**:
- ✅ Serverless workloads
- ✅ Batch jobs
- ✅ CI/CD pipelines
- ✅ Microservices with variable load
- ❌ GPU workloads
- ❌ Windows containers
- ❌ DaemonSets

**Fargate Profiles Created**:
- `default`: Pods in `default` namespace with label `fargate=true`
- `kube-system`: System pods in `kube-system` namespace

### Step 6: Review and Deploy

1. **Review all settings** carefully
2. **Click "Run workflow"**
3. **Monitor progress** in the Actions tab

**Deployment Timeline**:
- Security Scan: 2-3 minutes
- Terraform Plan: 3-5 minutes
- Approval (if prod): Variable
- Terraform Apply: 15-20 minutes
- **Total**: ~20-30 minutes

### Step 7: Verify Deployment

Check the **deployment summary** in the workflow run:

```
✅ Cluster Details
- Cluster Name: production-eks
- Environment: prod
- Kubernetes Version: 1.28.x
- Endpoint: https://xxxxx.eks.us-east-1.amazonaws.com
- Node Instance Types: t3.medium
- Desired Nodes: 3
- Fargate Enabled: false
```

## Configuration Options

### Basic Configuration

```yaml
# Minimum required configuration
cluster_name: "my-eks-cluster"
cluster_version: "1.28"
vpc_id: "vpc-xxx"
subnet_ids: ["subnet-xxx", "subnet-yyy"]

node_groups:
  general:
    desired_size: 2
    max_size: 4
    min_size: 1
    instance_types: ["t3.medium"]
```

### Production Configuration

```yaml
# Production-ready configuration
cluster_name: "production-eks"
cluster_version: "1.28"
vpc_id: "vpc-xxx"
subnet_ids: ["subnet-xxx", "subnet-yyy", "subnet-zzz"]

# Control plane access
cluster_endpoint_private_access: true
cluster_endpoint_public_access: true
cluster_endpoint_public_access_cidrs: ["10.0.0.0/8"]

# Logging
cluster_enabled_log_types:
  - api
  - audit
  - authenticator
  - controllerManager
  - scheduler

# Multiple node groups
node_groups:
  # General purpose nodes
  general:
    desired_size: 3
    max_size: 6
    min_size: 2
    instance_types: ["t3.large"]
    capacity_type: "ON_DEMAND"
    disk_size: 50
    labels:
      role: "general"
      tier: "application"
  
  # Spot instances for batch workloads
  spot:
    desired_size: 2
    max_size: 10
    min_size: 0
    instance_types: ["t3.large", "t3a.large"]
    capacity_type: "SPOT"
    disk_size: 50
    labels:
      role: "spot"
    taints:
      - key: "spot"
        value: "true"
        effect: "NoSchedule"

# Fargate for serverless workloads
fargate_profiles:
  default:
    selectors:
      - namespace: "default"
        labels:
          fargate: "true"
      - namespace: "batch-jobs"

# Add-ons
cluster_addons:
  vpc-cni:
    addon_version: "v1.15.0-eksbuild.2"
  coredns:
    addon_version: "v1.10.1-eksbuild.2"
  kube-proxy:
    addon_version: "v1.28.1-eksbuild.1"
  aws-ebs-csi-driver:
    addon_version: "v1.24.0-eksbuild.1"

# Security
enable_irsa: true
create_kms_key: true

# Monitoring
cloudwatch_log_retention_days: 90

tags:
  Environment: "production"
  ManagedBy: "terraform"
  CostCenter: "engineering"
```

## Post-Deployment Setup

### 1. Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name production-eks

# Verify connection
kubectl get nodes
kubectl get pods -A

# Check cluster info
kubectl cluster-info
```

### 2. Verify Node Groups

```bash
# List nodes
kubectl get nodes -o wide

# Check node labels
kubectl get nodes --show-labels

# Describe a node
kubectl describe node <node-name>
```

### 3. Install Essential Tools

#### AWS Load Balancer Controller

```bash
# Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Create IAM role for service account
eksctl create iamserviceaccount \
  --cluster=production-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

#### Cluster Autoscaler

```bash
# Download manifest
curl -o cluster-autoscaler-autodiscover.yaml \
  https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit and apply
kubectl apply -f cluster-autoscaler-autodiscover.yaml

# Verify
kubectl -n kube-system logs -f deployment/cluster-autoscaler
```

#### Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl top nodes
kubectl top pods -A
```

### 4. Deploy Sample Application

```yaml
# sample-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
# Deploy
kubectl apply -f sample-app.yaml

# Check status
kubectl get deployments
kubectl get pods
kubectl get services

# Get load balancer URL
kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Common Use Cases

### Use Case 1: Development Cluster

**Requirements**: Small, cost-effective cluster for development

```yaml
# Via GitHub Actions UI
Action: apply
Environment: dev
Cluster Name: dev-eks
Kubernetes Version: 1.28
Instance Types: t3.small
Desired Size: 2
Min Size: 1
Max Size: 3
Enable Fargate: false
```

**Cost**: ~$150/month (2 t3.small nodes + control plane)

### Use Case 2: Production Cluster with High Availability

**Requirements**: Multi-AZ, auto-scaling, production-grade

```yaml
# Via GitHub Actions UI
Action: apply
Environment: prod
Cluster Name: prod-eks
Kubernetes Version: 1.28
Instance Types: t3.large,t3a.large,m5.large
Desired Size: 4
Min Size: 3
Max Size: 10
Enable Fargate: false
```

**Additional Configuration** (in terraform.tfvars):
```hcl
node_groups = {
  general = {
    desired_size   = 4
    max_size       = 10
    min_size       = 3
    instance_types = ["t3.large", "t3a.large", "m5.large"]
    capacity_type  = "ON_DEMAND"
    labels = {
      role = "general"
    }
  }
}

cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]
cloudwatch_log_retention_days = 90
```

**Cost**: ~$500-800/month (4-10 t3.large nodes + control plane)

### Use Case 3: Mixed Workload (On-Demand + Spot)

**Requirements**: Cost optimization with Spot instances for batch jobs

```yaml
# Deploy via workflow with custom terraform.tfvars
node_groups = {
  # On-demand for critical workloads
  on_demand = {
    desired_size   = 2
    max_size       = 4
    min_size       = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    labels = {
      workload = "critical"
    }
  }
  
  # Spot for batch processing
  spot = {
    desired_size   = 3
    max_size       = 20
    min_size       = 0
    instance_types = ["t3.large", "t3a.large", "t2.large"]
    capacity_type  = "SPOT"
    labels = {
      workload = "batch"
    }
    taints = [
      {
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
  }
}
```

**Deploy Batch Job on Spot**:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    spec:
      nodeSelector:
        workload: batch
      tolerations:
      - key: "spot"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      containers:
      - name: batch-processor
        image: my-batch-image:latest
      restartPolicy: Never
```

**Cost Savings**: 60-70% on batch workloads

### Use Case 4: Serverless with Fargate

**Requirements**: No node management, pay-per-pod

```yaml
# Via GitHub Actions UI
Action: apply
Environment: prod
Cluster Name: serverless-eks
Kubernetes Version: 1.28
Instance Types: t3.medium
Desired Size: 1  # Minimal nodes for system pods
Min Size: 1
Max Size: 2
Enable Fargate: true
```

**Deploy to Fargate**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fargate-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fargate-app
  template:
    metadata:
      labels:
        app: fargate-app
        fargate: "true"  # This label triggers Fargate
    spec:
      containers:
      - name: app
        image: nginx:latest
```

**Cost**: Pay only for pod vCPU/memory usage

## Troubleshooting

### Issue 1: Nodes Not Joining Cluster

**Symptoms**:
```bash
kubectl get nodes
# No nodes or nodes in NotReady state
```

**Diagnosis**:
```bash
# Check node group status in AWS Console
aws eks describe-nodegroup \
  --cluster-name production-eks \
  --nodegroup-name general

# Check CloudWatch logs
aws logs tail /aws/eks/production-eks/cluster --follow
```

**Common Causes**:
1. **Security Group Issues**: Nodes can't communicate with control plane
2. **Subnet Issues**: No available IPs or wrong subnet type
3. **IAM Issues**: Node IAM role missing permissions

**Solutions**:
```bash
# Verify security groups allow required traffic
# Control plane security group should allow:
# - Ingress: 443 from node security group
# - Egress: 1025-65535 to node security group

# Node security group should allow:
# - Ingress: 1025-65535 from control plane security group
# - Ingress: All traffic from itself (for pod-to-pod)
# - Egress: All traffic

# Check IAM role policies
aws iam list-attached-role-policies \
  --role-name production-eks-node-group-role
```

### Issue 2: Pods Stuck in Pending

**Symptoms**:
```bash
kubectl get pods
# NAME                    READY   STATUS    RESTARTS   AGE
# my-app-xxx-yyy          0/1     Pending   0          5m
```

**Diagnosis**:
```bash
# Describe the pod
kubectl describe pod my-app-xxx-yyy

# Common messages:
# - "Insufficient cpu"
# - "Insufficient memory"
# - "0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector"
```

**Solutions**:

**Insufficient Resources**:
```bash
# Scale up node group
# Go to GitHub Actions → EKS Infrastructure
# Update Max Size and Desired Size

# Or enable cluster autoscaler (see post-deployment setup)
```

**Node Selector Issues**:
```yaml
# Check pod spec
kubectl get pod my-app-xxx-yyy -o yaml | grep -A 5 nodeSelector

# Verify nodes have matching labels
kubectl get nodes --show-labels
```

**Taints/Tolerations**:
```bash
# Check node taints
kubectl describe nodes | grep -A 5 Taints

# Add toleration to pod if needed
```

### Issue 3: Cannot Access Cluster

**Symptoms**:
```bash
kubectl get nodes
# error: You must be logged in to the server (Unauthorized)
```

**Solutions**:

**Update kubeconfig**:
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name production-eks \
  --profile your-aws-profile
```

**Verify AWS credentials**:
```bash
aws sts get-caller-identity
```

**Check IAM permissions**:
```bash
# Your IAM user/role needs:
# - eks:DescribeCluster
# - eks:ListClusters
```

**Add IAM user to aws-auth ConfigMap**:
```bash
kubectl edit configmap aws-auth -n kube-system

# Add under mapUsers:
- userarn: arn:aws:iam::ACCOUNT_ID:user/USERNAME
  username: USERNAME
  groups:
    - system:masters
```

### Issue 4: High Costs

**Diagnosis**:
```bash
# Check node count
kubectl get nodes

# Check pod distribution
kubectl get pods -A -o wide

# Check resource requests
kubectl describe nodes | grep -A 5 "Allocated resources"
```

**Solutions**:

1. **Right-size node groups**:
   - Use smaller instance types for dev/test
   - Enable cluster autoscaler
   - Set appropriate min/max sizes

2. **Use Spot instances**:
   - 60-70% cost savings
   - Good for batch jobs and stateless apps

3. **Enable Fargate for variable workloads**:
   - Pay only for what you use
   - No idle node costs

4. **Optimize pod resource requests**:
   ```yaml
   resources:
     requests:
       cpu: 100m      # Don't over-request
       memory: 128Mi
     limits:
       cpu: 500m
       memory: 512Mi
   ```

5. **Use Reserved Instances** (for production):
   - 30-50% savings for 1-year commitment

## Best Practices

### 1. Security

✅ **Enable private endpoint access**
```hcl
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = false  # Or restrict CIDRs
```

✅ **Use IRSA for pod IAM permissions**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/MyAppRole
```

✅ **Enable all control plane logs**
```hcl
cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

✅ **Use Pod Security Standards**
```bash
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
```

### 2. High Availability

✅ **Deploy across multiple AZs**
```hcl
subnet_ids = ["subnet-az1", "subnet-az2", "subnet-az3"]
```

✅ **Use Pod Disruption Budgets**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

✅ **Configure pod anti-affinity**
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: my-app
        topologyKey: topology.kubernetes.io/zone
```

### 3. Resource Management

✅ **Set resource requests and limits**
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

✅ **Use Horizontal Pod Autoscaler**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

✅ **Enable cluster autoscaler**
```bash
# See post-deployment setup section
```

### 4. Monitoring

✅ **Install metrics-server**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

✅ **Use Container Insights**
```bash
# Enable in CloudWatch Console
# Or use CloudWatch agent DaemonSet
```

✅ **Set up alerts**
```yaml
# Example: Alert on high CPU
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudwatch-config
data:
  cwagentconfig.json: |
    {
      "metrics": {
        "namespace": "EKS/Cluster",
        "metrics_collected": {
          "cpu": {
            "measurement": [
              {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}
            ]
          }
        }
      }
    }
```

### 5. Cost Optimization

✅ **Use appropriate instance types**
- Dev: t3.small, t3.medium
- Prod: t3.large, m5.large, r5.large

✅ **Enable cluster autoscaler**
- Scale down during off-hours
- Scale up during peak times

✅ **Use Spot instances for batch workloads**
- 60-70% cost savings
- Configure interruption handling

✅ **Right-size pods**
- Monitor actual usage
- Adjust requests/limits accordingly

✅ **Use Fargate for variable workloads**
- Pay only for pod runtime
- No idle node costs

## Next Steps

1. **Deploy your first application**
   - See sample application in post-deployment section
   - Follow Kubernetes best practices

2. **Set up CI/CD**
   - Integrate with GitHub Actions
   - Use ArgoCD or Flux for GitOps

3. **Configure monitoring**
   - Install Prometheus/Grafana
   - Set up CloudWatch Container Insights
   - Configure alerts

4. **Implement security**
   - Use Pod Security Standards
   - Enable network policies
   - Scan images for vulnerabilities

5. **Optimize costs**
   - Enable cluster autoscaler
   - Use Spot instances
   - Right-size resources

## Cleanup and Destroy

### Before Destroying

⚠️ **CRITICAL**: EKS cluster deletion is complex and requires careful cleanup of all resources.

**Pre-Destruction Checklist**:
- [ ] **Backup all critical data** from persistent volumes
- [ ] **Export cluster configurations** (deployments, services, configmaps)
- [ ] **Delete all Kubernetes resources** (deployments, services, ingresses)
- [ ] **Delete all persistent volumes** and claims
- [ ] **Delete all load balancers** created by services
- [ ] **Delete all node groups** and Fargate profiles
- [ ] **Remove all add-ons**
- [ ] Notify team members
- [ ] Document cluster configuration
- [ ] Update DNS records

### Method 1: Via GitHub Actions (Recommended)

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → EKS Infrastructure
   ```

2. **Click "Run workflow"**

3. **Configure destroy settings**:
   ```yaml
   Action: destroy
   Environment: dev  # or staging/prod
   Cluster Name: my-app-cluster  # Must match existing
   Kubernetes Version: 1.28  # Must match existing
   Node Group Instance Type: t3.medium  # Must match existing
   Desired Node Count: 2  # Must match existing
   Enable Fargate: false  # Must match existing
   AWS Region: us-east-1  # Must match existing
   ```

4. **Important**: Clean up Kubernetes resources first
   - Delete all workloads before destroying cluster
   - Workflow will fail if resources remain

5. **Review destroy plan**
   - Workflow will show what will be destroyed
   - Verify the cluster name is correct

6. **Approve and execute** (for prod environment)
   - Production requires manual approval
   - **Double-check cluster name** before approving

7. **Monitor destruction**
   - Watch the workflow logs
   - May take 10-15 minutes

**Expected Output**:
```
✅ EKS Cluster Destroyed Successfully!

Destroyed Resources:
- EKS Cluster: my-app-cluster
- Node Groups: 2 node groups deleted
- Fargate Profiles: 1 profile deleted
- Security Groups: 3 security groups deleted
- IAM Roles: 5 IAM roles deleted
- Launch Templates: 2 launch templates deleted

Cleanup completed in 12 minutes.
```

### Method 2: Via kubectl and AWS CLI

#### Step 1: Backup Cluster Configuration

```bash
CLUSTER_NAME="my-app-cluster"
BACKUP_DIR="./eks-backup-$(date +%Y%m%d)"

mkdir -p $BACKUP_DIR

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1

# Export all resources
kubectl get all --all-namespaces -o yaml > $BACKUP_DIR/all-resources.yaml

# Export specific resources
kubectl get deployments --all-namespaces -o yaml > $BACKUP_DIR/deployments.yaml
kubectl get services --all-namespaces -o yaml > $BACKUP_DIR/services.yaml
kubectl get configmaps --all-namespaces -o yaml > $BACKUP_DIR/configmaps.yaml
kubectl get secrets --all-namespaces -o yaml > $BACKUP_DIR/secrets.yaml
kubectl get ingresses --all-namespaces -o yaml > $BACKUP_DIR/ingresses.yaml
kubectl get persistentvolumes -o yaml > $BACKUP_DIR/pvs.yaml
kubectl get persistentvolumeclaims --all-namespaces -o yaml > $BACKUP_DIR/pvcs.yaml

# Export Helm releases
helm list --all-namespaces -o yaml > $BACKUP_DIR/helm-releases.yaml

echo "Backup completed: $BACKUP_DIR"
```

#### Step 2: Delete Kubernetes Resources

```bash
# Delete all deployments
kubectl delete deployments --all --all-namespaces

# Delete all services (except kubernetes service)
kubectl delete services --all --all-namespaces --field-selector metadata.name!=kubernetes

# Delete all ingresses
kubectl delete ingresses --all --all-namespaces

# Delete all persistent volume claims
kubectl delete pvc --all --all-namespaces

# Wait for load balancers to be deleted
echo "Waiting for load balancers to be deleted..."
sleep 60

# Verify no load balancers remain
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, '$CLUSTER_NAME')]" \
  --output table
```

#### Step 3: Delete Fargate Profiles

```bash
# List Fargate profiles
FARGATE_PROFILES=$(aws eks list-fargate-profiles \
  --cluster-name $CLUSTER_NAME \
  --query 'fargateProfileNames' \
  --output text)

# Delete each Fargate profile
for PROFILE in $FARGATE_PROFILES; do
  echo "Deleting Fargate profile: $PROFILE"
  aws eks delete-fargate-profile \
    --cluster-name $CLUSTER_NAME \
    --fargate-profile-name $PROFILE
done

# Wait for deletion
for PROFILE in $FARGATE_PROFILES; do
  echo "Waiting for Fargate profile $PROFILE to delete..."
  aws eks wait fargate-profile-deleted \
    --cluster-name $CLUSTER_NAME \
    --fargate-profile-name $PROFILE
done
```

#### Step 4: Delete Node Groups

```bash
# List node groups
NODE_GROUPS=$(aws eks list-nodegroups \
  --cluster-name $CLUSTER_NAME \
  --query 'nodegroups' \
  --output text)

# Delete each node group
for NG in $NODE_GROUPS; do
  echo "Deleting node group: $NG"
  aws eks delete-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NG
done

# Wait for deletion
for NG in $NODE_GROUPS; do
  echo "Waiting for node group $NG to delete..."
  aws eks wait nodegroup-deleted \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NG
done
```

#### Step 5: Delete Add-ons

```bash
# List add-ons
ADDONS=$(aws eks list-addons \
  --cluster-name $CLUSTER_NAME \
  --query 'addons' \
  --output text)

# Delete each add-on
for ADDON in $ADDONS; do
  echo "Deleting add-on: $ADDON"
  aws eks delete-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name $ADDON
done

# Wait for deletion
for ADDON in $ADDONS; do
  echo "Waiting for add-on $ADDON to delete..."
  aws eks wait addon-deleted \
    --cluster-name $CLUSTER_NAME \
    --addon-name $ADDON 2>/dev/null || true
done
```

#### Step 6: Delete EKS Cluster

```bash
# Delete the cluster
echo "Deleting EKS cluster: $CLUSTER_NAME"
aws eks delete-cluster --name $CLUSTER_NAME

# Wait for deletion
echo "Waiting for cluster to delete (this may take 10-15 minutes)..."
aws eks wait cluster-deleted --name $CLUSTER_NAME

echo "✅ EKS cluster deleted successfully!"
```

#### Step 7: Clean Up Associated Resources

```bash
# Delete security groups (created by EKS)
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

for SG_ID in $SG_IDS; do
  echo "Deleting security group: $SG_ID"
  aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null || true
done

# Delete IAM roles (if created separately)
# Note: Be careful with this - only delete roles you created
ROLE_NAMES=$(aws iam list-roles \
  --query "Roles[?contains(RoleName, '$CLUSTER_NAME')].RoleName" \
  --output text)

for ROLE in $ROLE_NAMES; do
  echo "Found IAM role: $ROLE"
  # Detach policies
  POLICIES=$(aws iam list-attached-role-policies \
    --role-name $ROLE \
    --query 'AttachedPolicies[*].PolicyArn' \
    --output text)
  
  for POLICY in $POLICIES; do
    aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY
  done
  
  # Delete role
  aws iam delete-role --role-name $ROLE
done

# Delete CloudWatch log groups
LOG_GROUPS=$(aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" \
  --query 'logGroups[*].logGroupName' \
  --output text)

for LOG_GROUP in $LOG_GROUPS; do
  echo "Deleting log group: $LOG_GROUP"
  aws logs delete-log-group --log-group-name $LOG_GROUP
done
```

### Automated Cleanup Script

```bash
#!/bin/bash
# delete-eks-cluster.sh - Automated EKS cluster deletion

set -e

CLUSTER_NAME="$1"
REGION="${2:-us-east-1}"

if [ -z "$CLUSTER_NAME" ]; then
  echo "Usage: $0 <cluster-name> [region]"
  exit 1
fi

echo "Starting EKS cluster deletion: $CLUSTER_NAME"
echo "Region: $REGION"
echo "This may take 15-20 minutes..."

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# 1. Delete Kubernetes resources
echo "Step 1: Deleting Kubernetes resources..."
kubectl delete deployments --all --all-namespaces --timeout=5m || true
kubectl delete services --all --all-namespaces --field-selector metadata.name!=kubernetes --timeout=5m || true
kubectl delete ingresses --all --all-namespaces --timeout=5m || true
kubectl delete pvc --all --all-namespaces --timeout=5m || true

# Wait for load balancers
echo "Waiting for load balancers to be deleted..."
sleep 60

# 2. Delete Fargate profiles
echo "Step 2: Deleting Fargate profiles..."
FARGATE_PROFILES=$(aws eks list-fargate-profiles \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --query 'fargateProfileNames' \
  --output text)

for PROFILE in $FARGATE_PROFILES; do
  echo "Deleting Fargate profile: $PROFILE"
  aws eks delete-fargate-profile \
    --cluster-name $CLUSTER_NAME \
    --fargate-profile-name $PROFILE \
    --region $REGION
done

for PROFILE in $FARGATE_PROFILES; do
  aws eks wait fargate-profile-deleted \
    --cluster-name $CLUSTER_NAME \
    --fargate-profile-name $PROFILE \
    --region $REGION 2>/dev/null || true
done

# 3. Delete node groups
echo "Step 3: Deleting node groups..."
NODE_GROUPS=$(aws eks list-nodegroups \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --query 'nodegroups' \
  --output text)

for NG in $NODE_GROUPS; do
  echo "Deleting node group: $NG"
  aws eks delete-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NG \
    --region $REGION
done

for NG in $NODE_GROUPS; do
  aws eks wait nodegroup-deleted \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NG \
    --region $REGION
done

# 4. Delete add-ons
echo "Step 4: Deleting add-ons..."
ADDONS=$(aws eks list-addons \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --query 'addons' \
  --output text)

for ADDON in $ADDONS; do
  echo "Deleting add-on: $ADDON"
  aws eks delete-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name $ADDON \
    --region $REGION
done

# 5. Delete cluster
echo "Step 5: Deleting EKS cluster..."
aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REGION

# 6. Clean up security groups
echo "Step 6: Cleaning up security groups..."
sleep 30
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" \
  --region $REGION \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

for SG_ID in $SG_IDS; do
  aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null || true
done

echo "✅ EKS cluster $CLUSTER_NAME deleted successfully!"
```

Usage:
```bash
chmod +x delete-eks-cluster.sh
./delete-eks-cluster.sh my-app-cluster us-east-1
```

### Verify Cleanup

```bash
# Verify cluster is deleted
aws eks describe-cluster --name $CLUSTER_NAME --region us-east-1
# Should return error: ResourceNotFoundException

# Check for orphaned load balancers
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, '$CLUSTER_NAME')]"

# Check for orphaned security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned"

# Check for orphaned volumes
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned"
```

### Cost Savings After Destruction

**Immediate Savings**:
- EC2 instance charges stop (node groups)
- Fargate vCPU/memory charges stop
- EKS cluster charge stops ($0.10/hour = $73/month)
- Load balancer charges stop
- Data transfer charges stop

**Example**:
```
Before:
- EKS cluster: $73/month
- 3 × t3.medium nodes: $90/month
- 2 × ALB: $32/month
Total: $195/month

After: $0/month
Savings: $195/month or $2,340/year
```

### Troubleshooting Destroy Issues

#### Issue: Cannot Delete Cluster - Node Groups Exist

**Error**: "Cluster has nodegroups attached"

**Solution**:
```bash
# Delete all node groups first
NODE_GROUPS=$(aws eks list-nodegroups \
  --cluster-name $CLUSTER_NAME \
  --query 'nodegroups' \
  --output text)

for NG in $NODE_GROUPS; do
  aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NG
  aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name $NG
done

# Then delete cluster
aws eks delete-cluster --name $CLUSTER_NAME
```

#### Issue: Load Balancers Not Deleted

**Error**: Security groups cannot be deleted due to load balancers

**Solution**:
```bash
# Find load balancers created by cluster
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$VPC_ID']"

# Delete manually
aws elbv2 delete-load-balancer --load-balancer-arn <arn>

# Wait for deletion
sleep 60

# Then delete security groups
aws ec2 delete-security-group --group-id sg-xxx
```

#### Issue: Persistent Volumes Not Deleted

**Error**: EBS volumes remain after cluster deletion

**Solution**:
```bash
# Find volumes created by cluster
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" \
  --query 'Volumes[*].[VolumeId,State,Size]' \
  --output table

# Delete volumes
VOLUME_IDS=$(aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" \
  --query 'Volumes[*].VolumeId' \
  --output text)

for VOL_ID in $VOLUME_IDS; do
  echo "Deleting volume: $VOL_ID"
  aws ec2 delete-volume --volume-id $VOL_ID
done
```

#### Issue: IAM Roles Cannot Be Deleted

**Error**: "Role is being used by..."

**Solution**:
```bash
# Detach all policies first
ROLE_NAME="eks-cluster-role"

POLICIES=$(aws iam list-attached-role-policies \
  --role-name $ROLE_NAME \
  --query 'AttachedPolicies[*].PolicyArn' \
  --output text)

for POLICY in $POLICIES; do
  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY
done

# Delete inline policies
INLINE_POLICIES=$(aws iam list-role-policies \
  --role-name $ROLE_NAME \
  --query 'PolicyNames' \
  --output text)

for POLICY in $INLINE_POLICIES; do
  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $POLICY
done

# Now delete role
aws iam delete-role --role-name $ROLE_NAME
```

### Best Practices for Safe Deletion

✅ **Always backup before deleting**
```bash
# Export all Kubernetes resources
kubectl get all --all-namespaces -o yaml > backup.yaml

# Backup persistent data
kubectl get pv -o yaml > pvs-backup.yaml
```

✅ **Use kubectl drain before deleting nodes**
```bash
# Drain nodes gracefully
kubectl get nodes -o name | xargs -I {} kubectl drain {} --ignore-daemonsets --delete-emptydir-data
```

✅ **Delete resources in correct order**
```
1. Kubernetes workloads (deployments, services)
2. Persistent volumes
3. Fargate profiles
4. Node groups
5. Add-ons
6. Cluster
7. Associated AWS resources
```

✅ **Test deletion in dev environment first**
```bash
# Test in dev
./delete-eks-cluster.sh dev-cluster

# Then apply to prod
./delete-eks-cluster.sh prod-cluster
```

✅ **Monitor costs during deletion**
```bash
# Check for remaining resources
aws ce get-cost-and-usage \
  --time-period Start=2026-05-01,End=2026-05-16 \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter file://filter.json
```

## Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Workshop](https://www.eksworkshop.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check AWS CloudWatch logs
- Contact DevOps team

---

**Last Updated**: May 2026
