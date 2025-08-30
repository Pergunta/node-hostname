# Node Hostname Platform - Kubernetes Deployment



## 📋 Overview

Production-grade platform engineering solution demonstrating modern DevOps practices with a fully private GKE cluster, GitOps deployment strategy, and enterprise-level security.

###  Key Features

- 🔒 **Fully Private GKE Cluster** - No public endpoint, accessed via Fleet/Connect Gateway
- 🏗️ **Infrastructure as Code** - Complete Terraform automation with remote state in GCS
- 🚢 **GitOps Deployment** - ArgoCD manages all deployments from Git
- 🔄 **CI/CD Pipeline** - GitHub Actions with Workload Identity Federation (no keys!)
- 🛡️ **Google Managed SSL** - Automatic HTTPS with ManagedCertificate
- 📦 **Artifact Registry** - Private container registry in GCP
- 🎯 **Zero-Touch Deployment** - Push to `prod` branch triggers automatic deployment

## 🏗️ Architecture

### System Architecture
```
┌────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                      │
│                    github.com/Pergunta/node-hostname           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Source Code            |  Kubernetes Manifests          │  │
│  │  ├── app.js            │  ├── deployment/prod/           │  │
│  │  ├── routes/           │  │   ├── deployment.yaml        │  │
│  │  ├── Dockerfile        │  │   ├── ingress.yaml           │  │
│  │  └── package.json      │  │   └── kustomization.yaml     │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────┬───────────────────────────────┬───────────────────┘
             │ Push to 'prod'                │ Watch 'prod' branch
             ↓                               ↓
┌─────────────────────────┐     ┌──────────────────────────┐
│   GitHub Actions CI/CD  │     │      ArgoCD (GitOps)     │
│                         │     │                          │
│ 1. Build Docker image   │     │ 1. Poll Git repo (3min)  │
│ 2. Push to Artifact Reg │     │ 2. Detect changes        │
│ 3. Update image tag     │     │ 3. Sync to cluster       │
│ 4. Commit to Git        │     │ 4. Apply manifests       │
└───────────┬─────────────┘     └────────────┬─────────────┘
            │                                 │
            ↓                                 ↓
┌────────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                      │
│                                                                │
│  ┌─────────────────────┐        ┌──────────────────────────┐   │
│  │  Artifact Registry  │        │   Private GKE Cluster    │   │
│  │                     │        │                          │   │
│  │ nh-docker/          │ Pull   │  ┌────────────────────┐  │   │
│  │  node-hostname:     │------->│  │  node-hostname     │  │   │
│  │   - sha-xxxxx       │        │  │  Deployment        │  │   │
│  │   - prod            │        │  │  (2 replicas)      │  │   │
│  └─────────────────────┘        │  └────────┬───────────┘  │   │
│                                 └──────────────────────────┘   │
│                                             ↓                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │          Global Load Balancer + SSL                  │      │
│  │  IP: 34.144.225.147                                  │      │
│  │  Cert: Google Managed Certificate                    │      │
│  └──────────────────────┬───────────────────────────────┘      │ 
└─────────────────────────┼──────────────────────────────────────┘
                          ↓
                   🌍 Internet Users
           https://34.144.225.147.sslip.io
```

### Network Architecture
```
┌───────────────────────────────────────────────────┐
│            VPC: assignment-cluster-vpc            │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │     Subnet: assignment-cluster-subnet       │  │
│  │     CIDR: 10.10.0.0/20                      │  │
│  │                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐   │  │
│  │  │   GKE Node 1    │  │   GKE Node 2    │   │  │
│  │  │  (Private IP)   │  │  (Private IP)   │   │  │
│  │  └────────┬────────┘  └────────┬────────┘   │  │
│  │           └──────────┬──────────┘           │  │
│  │                      ↓                      │  │
│  │           ┌──────────────────┐              │  │
│  │           │   Cloud NAT      │              │  │
│  │           │  (Egress Only)   │              │  │
│  │           └──────────────────┘              │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│  Control Plane (Private Endpoint)                 │
│  Access via: Connect Gateway                      │
└───────────────────────────────────────────────────┘
```

## 🚦 Live Demo

 **Application URL**: https://34.144.225.147.sslip.io  
 **Status**: ![Live](https://img.shields.io/badge/status-live-green)

## 📁 Repository Structure

```
.
├── terraform/
│   ├── remote-state/        # GCS bucket for Terraform state
│   │   └── main.tf
│   └── gke/                 # Private GKE infrastructure
│       ├── main.tf          # VPC, NAT, Private GKE
│       ├── artifact.tf      # Artifact Registry
│       └── outputs.tf       # Connection instructions
├── deployment/
│   ├── common/             # Shared K8s resources
│   │   ├── namespace.yaml
│   │   ├── service.yaml
│   │   └── argocd.yaml
│   └── prod/               # Production environment
│       ├── deployment.yaml
│       ├── ingress.yaml    # GCE Ingress
│       ├── managedcertificate.yaml
│       └── kustomization.yaml
├── argocd/
│   └── bootstrap.yaml      # ArgoCD application
├── .github/
│   └── workflows/
│       └── push_and_deploy.yaml  # CI/CD pipeline
├── routes/                 # Node.js application
├── Dockerfile             # Multi-stage build
└── README.md
```

## 🚀 Deployment Guide

### Prerequisites

- GCP Project with billing enabled ($300 free credits)
- `gcloud` CLI installed and configured
- `terraform` >= 1.13
- `kubectl` >= 1.28
- GitHub repository (fork this repo)

### Step 1: Infrastructure Setup

#### 1.1 Create Terraform State Bucket
```bash
cd terraform/remote-state
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"

# Note the bucket name output
export TFSTATE_BUCKET=$(terraform output -raw tfstate_bucket)
```

#### 1.2 Configure Backend
```bash
cd ../gke
# Update backend.tf with your bucket name
sed -i "s/bucket = \"\"/bucket = \"$TFSTATE_BUCKET\"/" backend.tf
```

#### 1.3 Deploy GKE Infrastructure
```bash
# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id = "YOUR_PROJECT_ID"
region = "europe-west1"
cluster_name = "assignment-cluster"
EOF

# Deploy infrastructure
terraform init
terraform apply -auto-approve

# Output connection command
terraform output connect_gateway_cmd
```

### Step 2: Connect to Private Cluster

```bash
# No VPN needed! Use Connect Gateway:
gcloud container fleet memberships get-credentials assignment-cluster \
  --project YOUR_PROJECT_ID

# Verify connection
kubectl get nodes
```

### Step 3: Install ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Step 4: Configure ArgoCD Application

```bash
# Apply ArgoCD application pointing to your repo
kubectl apply -f argocd/bootstrap.yaml

# Port-forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access at: https://localhost:8080
```

### Step 5: GitHub Actions Setup

#### Configure Workload Identity Federation
```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions CI/CD"

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Set up Workload Identity Federation
gcloud iam workload-identity-pools create github \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Configure the provider
gcloud iam workload-identity-pools providers create-oidc github-actions \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"
```

#### Add GitHub Secrets
 
- `GCP_WORKLOAD_ID_PROVIDER`: The provider name from above
- `GCP_SA_EMAIL`: github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com

#### Add GitHub Variables
- `GCP_PROJECT_ID`: GCP project ID
- `GCP_REGION`: europe-west1
- `ARTIFACT_REPO`: nh-docker

### Step 6: Deploy Application

The deployment is **fully automated** through GitOps:

```bash
# Method 1: Automatic deployment (recommended)
git checkout -b prod
git push origin prod

# That's it! The pipeline will:
# 1. Build and push image (e.g., sha-014340e12c42)
# 2. Update deployment/prod/kustomization.yaml
# 3. Commit change back to prod branch
# 4. ArgoCD auto-syncs within 3 minutes

```

### Verify Deployment

```bash
# Watch the magic happen
kubectl get pods -n node-hostname -w

# Check the deployed version
kubectl describe deployment node-hostname -n node-hostname | grep Image

# Test the application
curl https://34.144.225.147.sslip.io
# Response: {"hostname":"node-hostname-xxxxx","version":"0.0.1"}
```


### View Application Logs
```bash
kubectl logs -f deployment/node-hostname -n node-hostname
```

### Check Deployment Status
```bash
kubectl get all -n node-hostname
```

### View Ingress & Certificate
```bash
# Check ingress status
kubectl describe ingress node-hostname -n node-hostname

# Check certificate provisioning
kubectl describe managedcertificate node-hostname-cert -n node-hostname
```

### Scale Application
```bash
kubectl scale deployment/node-hostname --replicas=5 -n node-hostname
```

## 🔐 Security Features

### Infrastructure Security
- ✅ **Private GKE Cluster** - No public control plane endpoint
- ✅ **Private Nodes** - Nodes in private subnet with Cloud NAT
- ✅ **Workload Identity** - Pod-level GCP IAM integration
- ✅ **Binary Authorization** - Ready to enable
- ✅ **Connect Gateway** - Secure kubectl without VPN

### CI/CD Security
- ✅ **Workload Identity Federation** - No service account keys!
- ✅ **Least Privilege IAM** - Minimal permissions
- ✅ **Immutable Image Tags** - SHA-based tagging
- ✅ **Automated Scanning** - Vulnerability scanning in Artifact Registry

### Application Security
- ✅ **Non-root Container** - Runs as user `node`
- ✅ **Health Checks** - Liveness and readiness probes
- ✅ **Resource Limits** - Memory and CPU constraints
- ✅ **Network Policies** - Ready to implement



## 🧹 Cleanup

```bash
# Remove all resources to avoid charges
cd terraform/gke
terraform destroy -auto-approve

cd ../remote-state
terraform destroy -auto-approve
```


## 🛠️ Troubleshooting

### Cannot connect to cluster
```bash
# Ensure Fleet API is enabled
gcloud services enable gkehub.googleapis.com connectgateway.googleapis.com

# Re-register membership
gcloud container fleet memberships register assignment-cluster \
  --gke-cluster=europe-west1/assignment-cluster
```

### ArgoCD not syncing
```bash
# Check application status
kubectl get application -n argocd
kubectl describe application node-hostname -n argocd

# Manual sync
argocd app sync node-hostname
```

### Certificate not provisioning
```bash
# Check DNS propagation
nslookup 34.144.225.147.sslip.io

# View certificate events
kubectl describe managedcertificate -n node-hostname
```

## 📚 Technologies Used

- **Cloud Platform**: Google Cloud Platform (GKE, Artifact Registry, Cloud NAT)
- **Container Orchestration**: Kubernetes 1.30
- **Infrastructure as Code**: Terraform 1.13+
- **GitOps**: ArgoCD 2.9+
- **CI/CD**: GitHub Actions with Workload Identity Federation
- **Configuration Management**: Kustomize
- **SSL/TLS**: Google Managed Certificates
- **DNS**: sslip.io (for demo purposes)
- **Application**: Node.js 20 with Express




## 👨‍💻 Author

**João Monteiro (Pergunta)**  


---
